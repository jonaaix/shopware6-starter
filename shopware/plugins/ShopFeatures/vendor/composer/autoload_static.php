<?php

// autoload_static.php @generated by Composer

namespace Composer\Autoload;

class ComposerStaticInite15e605f6827c4018f538a786e190e7a
{
    public static $prefixLengthsPsr4 = array (
        'S' => 
        array (
            'ShopFeatures\\ShopFeatures\\' => 26,
        ),
    );

    public static $prefixDirsPsr4 = array (
        'ShopFeatures\\ShopFeatures\\' => 
        array (
            0 => __DIR__ . '/../..' . '/src',
        ),
    );

    public static $classMap = array (
        'Composer\\InstalledVersions' => __DIR__ . '/..' . '/composer/InstalledVersions.php',
    );

    public static function getInitializer(ClassLoader $loader)
    {
        return \Closure::bind(function () use ($loader) {
            $loader->prefixLengthsPsr4 = ComposerStaticInite15e605f6827c4018f538a786e190e7a::$prefixLengthsPsr4;
            $loader->prefixDirsPsr4 = ComposerStaticInite15e605f6827c4018f538a786e190e7a::$prefixDirsPsr4;
            $loader->classMap = ComposerStaticInite15e605f6827c4018f538a786e190e7a::$classMap;

        }, null, ClassLoader::class);
    }
}
