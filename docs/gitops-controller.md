# Pull tabanli GitOps denetleyicisi

Bu denetleyici WSL icinde calisir ve GitHub deposunun `main` dalini duzenli
olarak kontrol eder. Yeni bir commit buldugunda commit'in izole bir kopyasini
olusturur, Ansible syntax kontrolunu yapar ve altyapi playbook'unu calistirir.

## Guvenlik modeli

- GitHub'dan yerel bilgisayara gelen bir baglanti yoktur.
- GitHub token'i veya self-hosted Actions runner kullanilmaz.
- Yalnizca CI'dan gecip `main` dalina birlestirilen commit'ler dagitilir.
- Basarisiz dagitimlarda commit basarili olarak isaretlenmez.
- Ayni anda yalnizca bir dagitim calisabilir.
- Uptime Kuma saglik kontrolu basarisizsa dagitim tamamlanmis sayilmaz.

## Kurulum

Komutlari WSL'de, depo kokunden calistirin:

```bash
cd /mnt/c/dev/gitops-iac-project
git switch main
git pull --ff-only

ansible-playbook \
  -K \
  -i localhost, \
  ansible/controller.yml
```

`-K`, WSL kullanicisinin `sudo` parolasini guvenli bicimde sorar.

## Kontrol

```bash
systemctl status gitops-deploy.timer --no-pager
systemctl list-timers gitops-deploy.timer --no-pager
sudo systemctl start gitops-deploy.service
sudo journalctl -u gitops-deploy.service -n 100 --no-pager
```

Son basariyla dagitilan commit:

```bash
sudo cat /var/lib/gitops-controller/last-successful-commit
git rev-parse origin/main
```

Iki commit de ayniysa `main` dali sunucuya basariyla uygulanmistir.

## Calisma bicimi

Zamanlayici yaklasik dakikada bir kontrol yapar. Yeni commit yoksa Ansible
calistirilmaz. Bir hata olursa systemd gunlugunde hata kalir ve commit basarili
olarak kaydedilmedigi icin sonraki turda yeniden denenir.
