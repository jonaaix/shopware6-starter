# Shopware Starter (production-ready) 🚀

> Production-ready Shopware 6 Starter Template – performant, scalable, and full-featured.

---

## Getting Started 🛠️

This starter setup is intended as a foundation for your own Shopware project. You should create your own repository
based on this template.

### Clone the Repository

```shell
git clone --depth=1 --branch=main <url>/shopware-starter.git \
&& cd shopware-starter && rm -rf .git && git init
```

### Initial Steps

```shell
cp .env.example .env
cp compose.example.yaml compose.yaml
```

* If you're testing locally, **uncomment** the port mapping in your new `compose.yaml`.
* If you're setting up for **production**, now is the time to:

    * Set passwords and keys in your `.env`
    * Update `compose.yaml` with your **proxy configuration**
* If you're setting up a **local** or **development environment**, also **uncomment the two lines
  below `# Development only`** in `compose.yaml` to enable dev-specific config files.

### Configure Shopware Project Files

Before starting the containers, you should configure your Shopware environment:

#### 1. Add Shopware Account Auth

Open the file `persistent-data/shopware/auth.json` and add your [Shopware account](https://account.shopware.com)
credentials to enable plugin installation via Composer.

#### 2. Register Custom Plugins

Open the file `persistent-data/shopware/composer.json` and add your required plugins to the `require` section.

#### 3. Adjust robots.txt

Open `persistent-data/shopware/robots.txt` and replace `domain.com` with your actual domain in the sitemap URL.

### Start and Initialize Containers

#### 1. Build Docker Images

```shell
./scripts/docker-build.sh
```

#### 2. Pull Images

```shell
docker compose pull --ignore-pull-failures
```

#### 3. Start Containers

```shell
docker compose up -d \
  && docker compose logs -f php varnish mysql redis
```

#### 4. Enter Container as Root

Open a new shell and `cd` into your `shopware-starter` directory, then run:

```shell
docker compose exec --user root php bash
```

#### 5. Run Shopware Initialization Script

```shell
. /z-init-data/copy-shopware.sh
```

#### 6. Exit Root Shell

```shell
exit
```

> From now on, you can enter the container as the default `www-data` user using:
>
> ```shell
> docker compose exec php bash
> ```

### Choose Your Setup Path

You now have two options to proceed:

#### Option 1: Start with a Fresh Database

* Open `shopware/shopware.yaml`
* Set `frw: true` to enable the **First Run Wizard**
* Recreate the PHP container:

```shell
docker compose up -d --force-recreate php
```

* Open your browser at [http://localhost:8000](http://localhost:8000) and follow the installation steps

#### Option 2: Import an Existing Database Dump

* Place your `dump.sql` file in the `./file-share/import/` directory
* Then run the following command **from the host**, not inside the container:

```shell
./docker/init/mysql-import-shopware.sh
```

* After the import is completed, open a shell inside the container:

```shell
docker compose exec php bash
```

* Now run the following commands **in order** to finalize your Shopware setup:

> ⚠️ The command `system:update:finish` can take VERY long. If it hangs up after completing migrations, cancel it and
> run it again.

1. `composer update`
2. `bin/console system:update:finish`
3. `bin/console assets:install --force`
4. `bin/console theme:refresh`
5. `bin/console theme:compile`
6. `bin/console media:update-path --force -vvv`
7. `bin/console dal:refresh:index --use-queue`
8. `bin/console es:admin:index`
9. `bin/console es:index`
10. `bin/console cache:clear`

---

## Additional Hints 💡

### 1. Switching to MariaDB

To use MariaDB instead of MySQL:

* Change the Docker image to `mariadb:lts`
* Set `DB_TYPE="mariadb"` in:

    * `./scripts/mysql-import-shopware.sh`
    * `./scripts/`

> ⚠️ Note: Changing the database type might **not be possible after Shopware is installed**.

### 2. CDN Strategy Compatibility

If you're upgrading from Shopware 6.4, make sure to add the legacy CDN strategy to your `.env`:

```env
SHOPWARE_CDN_STRATEGY_DEFAULT=physical_filename
```

This was the default prior to 6.5. It's nearly impossible to change the strategy afterwards, as the filesystem will be
broken.

### 3. Plugin Management via Composer

It is significantly faster and more reliable to manage plugins via Composer.

If you're migrating and want to disable all currently active plugins in the database, run:

```sql
UPDATE `plugin`
SET active = 0
WHERE active = 1;
```

---

## Production S3 Integration ☁️

> ⚠️ This section applies **only to the production environment**. It does not make sense for local development setups.

The production environment is designed to work with **S3-compatible storage**. This section explains how to configure
DigitalOcean Spaces as an S3 backend for Shopware assets.

### S3 Bucket Structure & CDN Performance 🌍

The S3 bucket is structured for clear separation of environments and file types:

```
bucket/<dev or prod>/sw6/<public or private>
```

This layout enables consistent handling of static assets, access control, and syncing routines between development and
production.

Thus update the path in your `.env` file according to your environment (`dev` or `prod`):
```env
S3_ROOT_DIR_PUBLIC=dev/sw6/public
S3_ROOT_DIR_PRIVATE=dev/sw6/private

S3_ROOT_DIR_PUBLIC=prod/sw6/public
S3_ROOT_DIR_PRIVATE=prod/sw6/private
```

### Enable CDN for Global Performance

We recommend using DigitalOcean’s **CDN feature** for better international performance. Simply enable CDN for your space
and set TTL (time to live) to `1 Week`.

Update your `.env` file accordingly:

```env
S3_URL=https://bucket.fra1.cdn.digitaloceanspaces.com
```

> 🔖 The `cdn` subdomain is intentional and used in the asset URLs to serve files through the CDN layer.

---

### Required Tools

Install the following tools on your server:

```shell
sudo apt-get install -y rclone s3cmd
```

### 1. Setup rclone

Create the file `~/.config/rclone/rclone.conf` with the following content:

```ini
[shopware]
type = s3
provider = DigitalOcean
access_key_id = 123
secret_access_key = 123
region = fra1
endpoint = fra1.digitaloceanspaces.com
```

### 2. Setup s3cmd

Create the file `~/.s3cfg-shopware` with the following content (used for listing and permission management):

```ini
[default]
access_key = 123
secret_key = 123
host_base = fra1.digitaloceanspaces.com
host_bucket = %(bucket)s.fra1.digitaloceanspaces.com
bucket_location = fra1
use_https = True
signature_v2 = False
```

> ⚠️ **Important:** The scripts included in this starter setup rely on these exact section headers (`[shopware]` for
> rclone and `[default]` for s3cmd) and file paths. **Do not rename or change them**, or the S3 automation will fail.

---

## S3 Maintenance Scripts ⚙️

The starter template includes helper scripts for managing your S3 buckets:

### 1. Daily Clone from Prod to Dev

This ensures your dev environment mirrors production assets daily, so you can test safely without breaking anything.

### 2. Update Cache-Control Header

This updates `Cache-Control` headers for newly uploaded files, enabling efficient local caching. Shopware does not
automatically set the Cache-Control header for media files, so this must be handled manually using a scheduled script.

### Setup via Cron

Open your crontab using `crontab -e` and add the following:

```cron
# Sync prod S3 to dev daily at 02:00
0 2 * * * /var/www/shopware6/scripts/s3-clone-prod-to-dev.sh > "$HOME/logs/s3-clone-prod-to-dev.log" 2>&1

# Update Cache-Control for files uploaded in the last hour
0 * * * * /var/www/shopware6/scripts/s3-public-cache-control.sh > "$HOME/logs/s3-public-cache-control.log" 2>&1
```

---

## Database Backups 💾

The script `./scripts/mysql-backup-to-s3.sh` creates a MySQL dump of both the **Shopware** and **WordPress** databases
and uploads it to the S3 bucket defined in your `.env` file under `S3_BACKUP_BUCKET`.

After the upload, it automatically runs `s3-clean-backups.sh`, which cleans up old backups, retaining only the last
`RETENTION_DAYS=30` (this default can be changed by editing the `s3-clean-backups.sh` script).

### Setup Scheduled Backups via Cron

You can define any number of cron tasks to run backups at desired intervals. Example:

```cron
# Shop Backups at 14:00 and 23:00
0 14 * * * /var/www/shopware6/scripts/mysql-backup-to-s3.sh > "$HOME/logs/mysql-backup-to-s3.log" 2>&1
0 23 * * * /var/www/shopware6/scripts/mysql-backup-to-s3.sh > "$HOME/logs/mysql-backup-to-s3.log" 2>&1
```

⚠️ Make sure you have correctly set up the `.s3cfg-shopware` s3cmd config as described in the S3 setup section.

---

## Deployment 🚀

After updating theme or plugin code, `git pull` alone is not sufficient for the changes to become visible in the
Shopware storefront.

This is because:

* The PHP container needs to be restarted due to **OPcache**
* The theme may need to be **recompiled**
* The Shopware **cache** may need to be cleared

To simplify this, you can run:

```shell
./scripts/deploy.php
```

This script runs `git pull`, and automatically determines (via `git diff`) which actions are required and performs them
accordingly.

In most cases, running this script is sufficient to fully deploy your changes.

---

## Cache Warmup with Spider 🕷️

This template includes a custom spider setup that crawls all sitemap URLs to warm up the Shopware HTTP and Varnish
cache.

### Setup Instructions

1. Copy the example config:

```shell
cp compose.spider.example.yaml compose.spider.yaml
```

2. For **each sitemap**, define **exactly one spider container** in the `compose.spider.yaml` file.

3. Make sure to correctly set the following environment variables for each instance:

```env
SITEMAP_DOMAIN=example.com
SITEMAP_URL=https://example.com/sitemap.xml
```

4. Start the spiders:

```shell
docker compose -f compose.spider.yaml up -d
```

Each spider will continuously loop through all sitemap links to keep the cache warm.

> ⚠️ **Be careful not to overload your server** — for example, do not run 30 spiders in parallel if you have 30
> languages.

---

## Updating Shopware 🆙

To update Shopware via the command line, follow these steps in the given order:

```shell
bin/console system:update:prepare
```

Update the version constraints in your `composer.json`, then run:

```shell
composer update
```

Continue with:

```shell
bin/console system:update:finish
```

> ⚠️ This command can take VERY long. If it hangs up after completing migrations, cancel it and run it again.

Then:

```shell
composer recipes:update
bin/console cache:clear
bin/console dal:refresh:index --use-queue
bin/console es:admin:index
bin/console es:index
bin/console assets:install
bin/console theme:compile
bin/console theme:refresh
bin/console cache:clear
```

> 💡 Always backup your database and test updates in a development environment before applying them to production!

---

## System Information 🧠

### Redis Databases

| DB | Purpose                            |
|----|------------------------------------|
| 0  | `framework.session`                |
| 1  | `shopware.increment.user_activity` |
| 2  | `shopware.increment.message_queue` |
| 3  | `shopware.cart`                    |
| 4  | `framework.lock`                   |

---

## Helpful Tools & Migrations 🧰

### 🧾 Aliases

The Shopware Docker image includes several helpful aliases for developer convenience:

### `bc` – shorthand for `bin/console`

```shell
bc cache:clear
```

### `pa` – alternative alias for when you're also mixing up frameworks

```shell
pa cache:clear
```

### `ll` – list directory contents with details

```shell
ll
```

These are available by default when working inside the `php` container.


### 📦 Migrate local files to S3

Install `rclone` on the Shopware server (or container) that has access to the `files/` directories. Follow the rclone
setup instructions as described earlier, then run:

```shell
rclone sync "files/media" "do:sw-bucket/prod/sw6/private/media" --delete-excluded --stats=1s --transfers 32 --checkers 64 --s3-acl private
```

### 🔁 Migrate existing flat S3 structure to the dev/prod model

If you're already using a flat S3 layout, convert it to the structure used in this template:

```shell
rclone sync do:sw-bucket/sw6-pub do:sw-bucket/prod/sw6/public --delete-excluded --progress --transfers 32 --checkers 64 --s3-acl public-read
```

### 🚫 Fix missing public ACLs (403 errors)

If public files return a **403 Forbidden**, ensure their ACL is correctly set:

```shell
s3cmd setacl s3://sw-bucket/dev/sw6/public/ --acl-public --recursive || true
```

> ⚠️ **Do NOT apply public ACLs to `/sw6/private/` paths!**

### 🌐 Change system default language (⚠️ Risky!)

Changing the default system locale can lead to serious issues. Do this **only** if you know how to fix resulting DB
issues manually:

```shell
php bin/console system:configure-shop --shop-locale=en-GB
```

---

## WordPress 📝

This template includes a basic **WordPress setup** that can be used to:

* Embed forms with more features than Shopware offers
* Build complex content pages that are otherwise difficult in Shopware
* It's not intended to be used as a dedicated website but rather as a headless content management system for
  Shopware.

> ⚠️ **Note:** The WordPress integration is currently a **work in progress**.

You can embed WordPress pages seamlessly using **iframe resizer**:
👉 [iframe-resizer.com/guides/wordpress](https://iframe-resizer.com/guides/wordpress/)

---

## License

MIT License
