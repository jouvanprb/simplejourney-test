# Simple Journey Indonesia - Shift Engineer (DevOps) Technical Test

Repositori ini berisi implementasi teknis untuk pengemasan aplikasi Go, mekanisme hotfix tanpa rebuild image, serta otomatisasi CI/CD menggunakan Jenkins.

---

## Part I: Build
Aplikasi dibangun menggunakan multi-stage Dockerfile untuk menghasilkan binary statis tanpa ketergantungan library host.

- **Build Command:**
```bash
  docker build --build-arg VERSION=1.0.0 -t sj-app:1.0.0 .
```

* **Final Image Size:** ~7.5 MB
* **Penjelasan Base Image:** Base image `scratch` dipilih pada tahap akhir karena benar-benar kosong (zero OS overhead). Pendekatan ini meminimalkan ukuran image secara drastis dan meniadakan kerentanan keamanan bawaan sistem operasi, karena container hanya mengeksekusi binary Go statis.

---

## Part II: Deploy & Hotfix

Aplikasi dijalankan dengan restart policy `always`:

```bash
docker run -d --name sj-container -p 8080:8080 --restart always sj-app:1.0.0

```

### Mekanisme Hotfix (Binary Swap)

Binary baru dikompilasi di host/CI dan disalin langsung ke dalam container tanpa menghapus container atau melakukan rebuild Docker image:

```bash
# 1. Compile binary hotfix
CGO_ENABLED=0 GOOS=linux go build -buildvcs=false -ldflags="-X main.version=1.0.1-hotfix" -o server-hotfix .

# 2. Salin binary dan restart container
docker cp server-hotfix sj-container:/server
docker restart sj-container

```

* **Verifikasi curl Sebelum Swap:**
```text
Hello, DevOps! version = 1.0.0

```


* **Verifikasi curl Sesudah Swap:**
```text
Hello, DevOps! version = 1.0.1-hotfix

```


* **Justifikasi Pendekatan:** Metode `docker cp` dipilih karena memberikan waktu henti (*downtime*) minimal (hanya sepersekian detik saat proses container restart). Pendekatan ini sangat efektif untuk skenario *emergency hotfix* di produksi tanpa harus menunggu proses *image pull* dan tanpa perlu konfigurasi awal *shared volume*.

Bukti eksekusi terminal: `docs/part2-hotfix.png`

---

## Part III: CI/CD with Jenkins

Pipeline terotomatisasi mencakup tahapan Checkout, Test, Build Image, Push Image, dan Deploy:

1. **Test Gate:** Pipeline langsung berhenti jika `go test ./...` gagal.
2. **Kredensial Aman:** Kredensial registry diikat menggunakan Jenkins Credentials Binding (`withCredentials`) tanpa rahasia hardcoded.
3. **Mekanisme Rollback:** Jika tahap deployment gagal di tengah jalan, pipeline dapat menjalankan blok `post { failure { ... } }` untuk menyalin kembali binary cadangan (`server.backup`) ke dalam container dan me-restart container, sehingga layanan langsung kembali ke versi stabil sebelumnya.

Bukti eksekusi pipeline sukses: `docs/pipeline-success.png`

