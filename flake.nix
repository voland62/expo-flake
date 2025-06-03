{
  description = "ecommerce";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };
      androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
      platformVersion = "35";
      
      pinnedJDK = pkgs.jdk17;
      buildToolsVersion = "35.0.0";
      # buildToolsVersion = "36.0.0";
      # ndkVersion = "25.1.8937393";
      ndkVersion = "27.1.12297006";
      my-androidComposition-args = {
        cmdLineToolsVersion = "8.0";
        toolsVersion = "26.1.1";
        platformToolsVersion = "35.0.2";
        # buildToolsVersions = [ buildToolsVersion "33.0.1" ];
        buildToolsVersions = [ buildToolsVersion ];
        includeEmulator = true;
        emulatorVersion = "35.6.2";
        platformVersions = [ platformVersion ];
        includeSources = false;
        includeSystemImages = true;
        # systemImageTypes = [ "google_apis_playstore" ];
        # systemImageTypes = [ "aosp_atd" ];
        systemImageTypes = [ "default"
                             "google_apis"
                           ];
        # systemImageTypes = [ "google_atd" ];
        # abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
        abiVersions = [  "arm64-v8a" "x86_64" ];
        # abiVersions = [ "armeabi-v7a"];
        # abiVersions = [ "x86_64" ];
        cmakeVersions = [ "3.10.2" "3.22.1" ];
        includeNDK = true;
        ndkVersions = [ ndkVersion ];
        useGoogleAPIs = false;
        useGoogleTVAddOns = false;
        includeExtras = [
          "extras;google;gcm"
        ];
        extraLicenses = [
          # Already accepted for you with the global accept_license = true or
          # licenseAccepted = true on androidenv.
          # "android-sdk-license"

          # These aren't, but are useful for more uncommon setups.
          "android-sdk-preview-license"
          "android-googletv-license"
          "android-sdk-arm-dbt-license"
          "google-gdk-license"
          "intel-android-extra-license"
          "intel-android-sysimage-license"
          "mips-android-sysimage-license"
        ];
      };
      androidComposition = androidEnv.composeAndroidPackages my-androidComposition-args;
      sdk = androidComposition.androidsdk;
      androidEmulator = androidEnv.emulateApp {
        name = "android-sdk-emulator-demo";
        configOptions = {
          "hw.keyboard" = "yes";
        };
        sdkExtraArgs = my-androidComposition-args; # sdkArgs;
      };
    in
    {
      devShell = pkgs.mkShell rec {
        buildInputs = with pkgs; [
          # Android
          pinnedJDK
          sdk
          pkg-config
          nodejs
          androidEmulator
        ];

        JAVA_HOME = pinnedJDK;
        ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
        ANDROID_NDK_ROOT = "${ANDROID_SDK_ROOT}/ndk-bundle";

        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_SDK_ROOT}/build-tools/${buildToolsVersion}/aapt2";
      };

      packages.android-emulator = androidEnv.emulateApp {
            name = "emulate-MyAndroidApp";
            platformVersion = platformVersion;
            abiVersion = "x86_64"; # armeabi-v7a, mips, x86_64, arm64-v8a
            systemImageType = "default";
            configOptions = {
              "hw.keyboard" = "yes";
            };
            # sdkExtraArgs = my-androidComposition-args;
          };
      
    });
}
