<?php declare(strict_types=1);

namespace ShopFeatures\ShopFeatures;

use Shopware\Core\Framework\Plugin;

class ShopFeaturesPlugin extends Plugin {
   public function getTemplatePriority(): int {
      return 100;
   }
}
