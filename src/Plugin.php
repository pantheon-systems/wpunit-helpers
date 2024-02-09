<?php
namespace Pantheon\WPUnitHelpers;

use Composer\Composer;
use Composer\IO\IOInterface;
use Composer\Plugin\PluginInterface;
use Composer\Plugin\Capable;
use Composer\EventDispatcher\EventSubscriberInterface;

class Plugin implements PluginInterface, EventSubscriberInterface
{
    protected $composer;
    protected $io;

    public function activate(Composer $composer, IOInterface $io)
    {
        $this->composer = $composer;
        $this->io = $io;
        $this->copyBinDirectory();
    }

    public function deactivate(Composer $composer, IOInterface $io)
    {
        // Nothing to do
    }

    public function uninstall(Composer $composer, IOInterface $io)
    {
        // Nothing to do
    }

    public static function getSubscribedEvents()
    {
        return array(
            'post-install-cmd' => ['copyBinDirectory'],
            'post-update-cmd' => ['copyBinDirectory'],
        );
    }

    public function copyBinDirectory()
    {
        $io = $this->io;
        $vendorDir = $this->composer->getConfig()->get('vendor-dir');
        $binDir = $vendorDir . '/pantheon-systems/wpunit-helpers/bin';
        $targetDir = dirname($vendorDir) . '/bin';
        
        if (!is_dir($binDir)) {
            $io->write("No bin directory found at $binDir");
            return;
        }
        if (!is_dir($targetDir) && !mkdir($targetDir, 0755, true)) {
            $io->write("Could not create target directory $targetDir");
            return;
        }
        
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($binDir, \RecursiveDirectoryIterator::SKIP_DOTS),
            \RecursiveIteratorIterator::SELF_FIRST
        );
        
        $filesAreIdentical = true;  // Assume true until proven otherwise
        foreach ($iterator as $item) {
            $targetPath = $targetDir . DIRECTORY_SEPARATOR . $iterator->getSubPathName();
            if ($item->isDir()) {
                if (!is_dir($targetPath) && !mkdir($targetPath, 0755, true)) {
                    $io->write("Failed to create directory $targetPath");
                }
            } else {
                $sourceHash = hash_file('sha256', $item->getPathName());
                $targetHash = file_exists($targetPath) ? hash_file('sha256', $targetPath) : '';
                if ($sourceHash !== $targetHash) {
                    $filesAreIdentical = false;  // Set to false as soon as one mismatch is found
                    if (!copy($item, $targetPath)) {
                        $io->write("Failed to copy $item");
                    }
                }
            }
        }
    
        $composerIncludes = "
        \"scripts\": {
            \"phpunit\": \"phpunit --do-not-cache-result\",
            \"test\": \"@phpunit\",
            \"test:install\": \"bin/install-local-tests.sh --skip-db=true\",
            \"test:install:withdb\": \"bin/install-local-tests.sh\"
        }";
    
        if (!$filesAreIdentical) {
            $io->write("Done copying files into /bin.");
            $io->write("You can now add the following to your composer.json file: \n $composerIncludes");
        } else {
            $io->write("/bin files are up to date");
        }
    }
}
