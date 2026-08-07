# Pull tabanli GitOps denetleyicisi

Bu denetleyici WSL icinde calisir ve GitHub deposunun `main` dalini duzenli
olarak kontrol eder. Yeni bir commit buldugunda commit'in izole bir kopyasini
olusturur, Ansible syntax kontrolunu yapar, altyapi playbook'unu calistirir ve
Uptime Kuma sagligini dogrular.

Commit degismese bile servis sagliksizsa istenen durum yeniden uygulanir. Bu
davranis denetleyiciye self-healing ozelligi kazandirir.

## Guvenlik modeli

- GitHub'dan yerel bilgisayara veya VM'ye gelen bir baglanti yoktur.
- GitHub token'i ve self-hosted Actions runner kullanilmaz.
- Yalnizca CI'dan gecip `main` dalina birlestirilen commit'ler dagitilir.
- Dagitim, `git archive` ile uretilen izole bir calisma kopyasindan yapilir.
- Basarisiz dagitimlarda commit basarili olarak isaretlenmez.
- Ayni anda yalnizca bir dagitim calisabilir.
- Uptime Kuma saglik kontrolu basarisizsa dagitim tamamlanmis sayilmaz.
- VM SSH kimligi denetleyiciye ozel `known_hosts` dosyasinda tutulur.
- SSH strict host key checking kapatilmaz.

## Kurulum

Komutlari WSL'de, depo kokunden calistirin:

```bash
cd /mnt/c/dev/gitops-iac-project
git switch main
git pull --ff-only

ansible-playbook \
  -K \
  -i localhost, \
  ansible/controller.yml \
  -e "gitops_controller_user=$(whoami)"
```

`-K`, WSL kullanicisinin `sudo` parolasini sorar.

Bazi WSL/sudo surumlerinde Ansible'in parola istemi zaman asimina ugrarsa once
sudo oturumunu acip playbook'u ayni PATH ile root olarak calistirin:

```bash
cd /mnt/c/dev/gitops-iac-project

CURRENT_WSL_USER="$(whoami)"
ANSIBLE_BIN="$(command -v ansible-playbook)"

sudo -v
sudo env "PATH=$PATH" "$ANSIBLE_BIN" \
  -i localhost, \
  ansible/controller.yml \
  -e "gitops_controller_user=$CURRENT_WSL_USER"
```

## Systemd bilesenleri

| Bilesen | Gorev |
|---|---|
| `gitops-deploy.timer` | Yaklasik dakikada bir kontrol baslatir |
| `gitops-deploy.service` | Tek seferlik GitOps dagitimini calistirir |
| `/opt/gitops-controller` | Denetleyici ve calisma dizinleri |
| `/var/lib/gitops-controller` | Basarili commit ve SSH kimlik durumu |

## Kontrol

```bash
systemctl status gitops-deploy.timer --no-pager
systemctl list-timers gitops-deploy.timer --no-pager
sudo journalctl -u gitops-deploy.service -n 100 --no-pager
```

Canli log:

```bash
sudo journalctl -fu gitops-deploy.service
```

Servisi beklemeden bir kez calistirmak icin:

```bash
sudo systemctl start gitops-deploy.service
```

## Commit durumunu dogrulama

```bash
cd /mnt/c/dev/gitops-iac-project
git fetch origin main

sudo cat /var/lib/gitops-controller/last-successful-commit
git rev-parse origin/main
```

Iki SHA ayniysa `main` dali basariyla uygulanmistir.

## Calisma bicimi

Yeni commit bulundugunda denetleyici:

1. Uzak `main` referansini gunceller.
2. Commit'in izole dagitim kopyasini olusturur.
3. Ansible syntax kontrolunu calistirir.
4. `ansible/site.yml` playbook'unu uygular.
5. `http://192.168.56.10` saglik kontrolunu yapar.
6. Basarili commit SHA'sini durum dosyasina atomik olarak yazar.

Yeni commit yoksa ve servis saglikliysa Ansible calistirilmaz:

```text
Yeni commit yok ve servis saglikli: <commit-sha>
```

Yeni commit yok fakat servis sagliksizsa istenen durum yeniden uygulanir:

```text
Commit ayni ancak servis sagliksiz; mevcut durum yeniden uygulanacak.
```

Bir hata olursa commit basarili olarak kaydedilmez ve sonraki timer dongusunde
yeniden denenir.

## Yeni VM ve SSH kimligi

VM silinip ayni IP ile yeniden olusturuldugunda SSH sunucu anahtari degisir.
Denetleyici:

1. `192.168.56.10:22` erisimini bekler.
2. Yeni SSH kimligini `ssh-keyscan` ile alir.
3. Kimligi `/var/lib/gitops-controller/known_hosts` dosyasina yazar.
4. Ansible'i strict host key checking ile calistirir.

Kullanicinin `~/.ssh/known_hosts` dosyasi denetleyicinin dosyasindan ayridir.
Elle Ansible komutu calistirirken eski kaydi temizlemek gerekebilir:

```bash
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.56.10
ssh-keyscan -H 192.168.56.10 >> ~/.ssh/known_hosts
```

## Self-healing testi

```bash
cd /mnt/c/dev/gitops-iac-project

ansible servers -i ansible/inventory.ini -b \
  -m command -a "docker stop uptime-kuma"

sudo journalctl -fu gitops-deploy.service
```

Denetleyici ayni commit'i gorur fakat saglik kontrolu basarisiz oldugu icin
Ansible'i yeniden uygular. Uptime Kuma yeniden calisir duruma gelir.

## Sorun giderme

Timer etkin degilse:

```bash
sudo systemctl enable --now gitops-deploy.timer
```

Son servis sonucunu ve loglari inceleyin:

```bash
systemctl status gitops-deploy.service --no-pager
sudo journalctl -u gitops-deploy.service -n 150 --no-pager
```

Son basarili commit kaydedilmemisse saglik kontrolunu dogrulayin:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://192.168.56.10
```

Beklenen HTTP kodu `200` veya `302` degeridir.
