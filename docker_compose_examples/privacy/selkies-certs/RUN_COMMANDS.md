## 🔐 Generate a Self-Signed SSL Certificate

To generate a self-signed HTTPS certificate valid for 27 years (10,000 days), follow these steps.

---

### ✅ 1. Install Required Tools

Make sure you have `openssl` installed. Run:

```bash
sudo apt update
sudo apt install openssl -y
```

---

### 🛠️ 2. Generate the Certificate

Run the following command **from inside the `selkies-certs` directory**:

```bash
openssl req -x509 -newkey rsa:4096 -sha256 -days 10000 -nodes \
  -keyout key.pem \
  -out cert.pem \
  -subj "/CN=localhost"
```

- `key.pem`: Your private key  
- `cert.pem`: Your self-signed certificate  
- `-days 10000`: Valid for ~27 years  
- `-subj "/CN=localhost"`: Sets the common name (adjust if needed)

---

### ℹ️ Notes

- This certificate is **self-signed**, so browsers will show a warning unless it's manually trusted.
- Ideal for **local development**, **testing**, or **internal services**.
- For public domains, use a trusted authority like [Let's Encrypt](https://letsencrypt.org/).
