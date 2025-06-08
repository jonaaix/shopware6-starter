import os
import scrapy
import logging
import gzip
import time
from io import BytesIO
from scrapy import Selector


class SitemapSpider(scrapy.Spider):
    name = "sitemap-spider"

    def start_requests(self):
        domain = os.environ.get("SITEMAP_DOMAIN")
        url = os.environ.get("SITEMAP_URL")

        if not domain or not url:
            raise ValueError("Missing SITEMAP_DOMAIN or SITEMAP_URL environment variable")

        self.allowed_domains = [domain]
        yield scrapy.Request(url, self.parse_sitemap)

    def parse_sitemap(self, response):
        data = Selector(text=response.body, type="xml").xpath('//ns:loc/text()', namespaces={"ns": "http://www.sitemaps.org/schemas/sitemap/0.9"})
        locations = data.getall()

        for sitemap_url in locations:
            logging.getLogger().info('\033[92mNext Sitemap: %s\033[0m', sitemap_url)
            if sitemap_url.endswith('.gz'):
                yield scrapy.Request(sitemap_url, self.parse_gzipped_sitemap)

    def parse_gzipped_sitemap(self, response):
        content = gzip.GzipFile(fileobj=BytesIO(response.body)).read()
        sitemap = scrapy.http.XmlResponse(response.url, body=content)

        data = Selector(text=sitemap.body, type="xml").xpath('//ns:loc/text()', namespaces={"ns": "http://www.sitemaps.org/schemas/sitemap/0.9"})
        urls = data.getall()

        random.shuffle(urls)
        for url in urls:
            time.sleep(2.8)
            yield scrapy.Request(url=url, callback=self.parse_page)

    def parse_page(self, response):
        title = response.css('title::text').get(default='')
        logging.getLogger().info('\033[96mDone: %s\033[0m', title)
