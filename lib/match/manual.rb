require 'securerandom'

module Match
  class Manual
    attr_accessor :changes_to_commit

    def run(params)
      UI.user_error!("You must supply the mobile_provision option or cert and p12 options when using manual mode") unless !params[:mobile_provision].nil? || !params[:cert].nil?
      if (!params[:cert].nil? && params[:p12].nil?) || (params[:cert].nil? && !params[:p12].nil?)
        UI.user_error!("You must supply both the cert and p12 options when using manual mode")
      end

      FastlaneCore::PrintTable.print_values(config: params,
                                   hide_keys: [:workspace, :username, :keychain_name, :force],
                                       title: "Summary for match #{Match::VERSION}")

      params[:workspace] = GitHelper.clone(params[:git_url], params[:shallow_clone])

      cert_type = self.cert_type(params)

      uuid = self.save_profile(params, cert_type)

      self.save_cert(params, cert_type)

      if self.changes_to_commit and !params[:readonly]
        FileUtils.touch File.join(params[:workspace], "match_manual.mark")
        message = GitHelper.generate_commit_message(params)
        GitHelper.commit_changes(params[:workspace], message, params[:git_url])
      end

      TablePrinter.print_summary(params, uuid)

      UI.success "Given keys, certificates and/or provisioning profiles have been put in match 🙌".green
    end

    def cert_type(params)
      cert_type = :distribution
      cert_type = :development if params[:type] == "development"
      cert_type = :enterprise if Match.enterprise? && params[:type] == "enterprise"

      cert_type
    end

    def save_profile(params, cert_type)
      has_profile = !params[:mobile_provision].nil?
      return unless has_profile

      UI.user_error!("The supplied mobile_provision option '#{params[:mobile_provision]}' is not a file") unless File.exist? params[:mobile_provision]

      prov_type = cert_type.to_sym
      profile_name = [Match::Generator.profile_type_name(prov_type), params[:app_identifier]].join("_").gsub("*", '\*') # this is important, as it shouldn't be a wildcard
      profile_path = File.join(params[:workspace], "profiles", prov_type.to_s, "#{profile_name}.mobileprovision")

      UI.verbose "Saving #{params[:mobile_provision]} to #{profile_path}"
      FileUtils.mkdir_p(File.dirname(profile_path))
      FileUtils.cp(params[:mobile_provision], profile_path)
      UI.message "Saved #{File.basename(profile_path)}."

      parsed = FastlaneCore::ProvisioningProfile.parse(profile_path)
      uuid = parsed["UUID"]

      self.changes_to_commit = true

      uuid
    end

    def save_cert(params, cert_type)
      has_cert = !params[:cert].nil?
      return unless has_cert

      certs = Dir[File.join(params[:workspace], "certs", cert_type.to_s, "*.cer")]
      keys = Dir[File.join(params[:workspace], "certs", cert_type.to_s, "*.p12")]

      if certs.count != 0
        FileUtils.rm certs.last
        UI.important "Removed #{File.basename(certs.last)}."
      end

      if keys.count != 0
        FileUtils.rm keys.last
        UI.important "Removed #{File.basename(keys.last)}."
      end

      cert_folder = File.join(params[:workspace], "certs", cert_type.to_s)
      FileUtils.mkdir_p(cert_folder)

      random_name = SecureRandom.hex.upcase
      cert_path = File.join(cert_folder, "#{random_name}.cer")
      key_path =  File.join(cert_folder, "#{random_name}.p12")

      FileUtils.cp(params[:cert], cert_path)
      UI.message "Saved #{File.basename(cert_path)}."
      FileUtils.cp(params[:p12], key_path)
      UI.message "Saved #{File.basename(key_path)}."

      self.changes_to_commit = true
    end
  end
end
