describe Match do
  describe Match::Runner do
    it "creates a new profile and certificate if it doesn't exist yet" do
      git_url = "https://github.com/fastlane/certificates"
      branch = "master"
      manual_password = false
      values = {
        app_identifier: "tools.fastlane.app",
        type: "appstore",
        git_url: git_url
      }

      config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
      repo_dir = Dir.mktmpdir
      cert_path = File.join(repo_dir, "something")
      profile_path = "./spec/fixtures/test.mobileprovision"

      expect(Match::GitHelper).to receive(:clone).with(git_url, true, manual_password: false, branch: branch).and_return(repo_dir)
      expect(Match::Generator).to receive(:generate_certificate).with(config, :distribution).and_return(cert_path)
      expect(Match::Generator).to receive(:generate_provisioning_profile).with(params: config,
                                                                            prov_type: :appstore,
                                                                       certificate_id: "something").and_return(profile_path)
      expect(FastlaneCore::ProvisioningProfile).to receive(:install).with(profile_path)
      expect(Match::GitHelper).to receive(:commit_changes).with(repo_dir, "[fastlane] Updated tools.fastlane.app for appstore", git_url)

      spaceship = "spaceship"
      expect(Match::SpaceshipEnsure).to receive(:new).and_return(spaceship)
      expect(spaceship).to receive(:certificate_exists).and_return(true)
      expect(spaceship).to receive(:profile_exists).and_return(true)
      expect(spaceship).to receive(:bundle_identifier_exists).and_return(true)

      Match::Runner.new.run(config)
    end

    it "uses existing certificates and profiles if they exist" do
      git_url = "https://github.com/fastlane/certificates"
      branch = "master"
      manual_password = false
      values = {
        app_identifier: "tools.fastlane.app",
        type: "appstore",
        git_url: git_url
      }

      config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
      repo_dir = "./spec/fixtures/existing"
      cert_path = "./spec/fixtures/existing/certs/distribution/E7P4EE896K.cer"
      key_path = "./spec/fixtures/existing/certs/distribution/E7P4EE896K.p12"
      keychain = "login.keychain"

      expect(Match::GitHelper).to receive(:clone).with(git_url, true, manual_password: false, branch: branch).and_return(repo_dir)
      expect(Match::Utils).to receive(:import).with(key_path, keychain).and_return(nil)
      expect(Match::GitHelper).to_not receive(:commit_changes)

      # To also install the certificate, fake that
      expect(FastlaneCore::CertChecker).to receive(:installed?).with(cert_path).and_return(false)
      expect(Match::Utils).to receive(:import).with(cert_path, keychain).and_return(nil)

      spaceship = "spaceship"
      expect(Match::SpaceshipEnsure).to receive(:new).and_return(spaceship)
      expect(spaceship).to receive(:certificate_exists).and_return(true)
      expect(spaceship).to receive(:profile_exists).and_return(true)
      expect(spaceship).to receive(:bundle_identifier_exists).and_return(true)

      Match::Runner.new.run(config)
    end
  end
end
