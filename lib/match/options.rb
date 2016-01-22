require 'fastlane_core'
require 'credentials_manager'

module Match
  class Options
    def self.available_options
      user = CredentialsManager::AppfileConfig.try_fetch_value(:apple_dev_portal_id)
      user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

      [
        FastlaneCore::ConfigItem.new(key: :git_url,
                                     env_name: "MATCH_GIT_URL",
                                     description: "URL to the git repo containing all the certificates",
                                     optional: false,
                                     short_option: "-r"),
        FastlaneCore::ConfigItem.new(key: :type,
                                     env_name: "MATCH_TYPE",
                                     description: "Create a development certificate instead of a distribution one",
                                     is_string: true,
                                     short_option: "-y",
                                     default_value: 'development',
                                     verify_block: proc do |value|
                                       unless Match.environments.include?(value)
                                         UI.user_error!("Unsupported environment #{value}, must be in #{Match.environments.join(', ')}")
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     short_option: "-a",
                                     env_name: "MATCH_APP_IDENTIFIER",
                                     description: "The bundle identifier of your app",
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)),
        FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: "-u",
                                     env_name: "MATCH_USERNAME",
                                     description: "Your Apple ID Username",
                                     default_value: user),
        FastlaneCore::ConfigItem.new(key: :keychain_name,
                                     short_option: "-s",
                                     env_name: "MATCH_KEYCHAIN_NAME",
                                     description: "Keychain the items should be imported to",
                                     default_value: "login.keychain"),
        FastlaneCore::ConfigItem.new(key: :readonly,
                                     env_name: "MATCH_READONLY",
                                     description: "Only fetch existing certificates and profiles, don't generate new ones",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :team_id,
                                     short_option: "-b",
                                     env_name: "FASTLANE_TEAM_ID",
                                     description: "The ID of your team if you're in multiple teams",
                                     optional: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_ID"] = value
                                     end),
        FastlaneCore::ConfigItem.new(key: :team_name,
                                     short_option: "-l",
                                     env_name: "FASTLANE_TEAM_NAME",
                                     description: "The name of your team if you're in multiple teams",
                                     optional: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_name),
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_NAME"] = value
                                     end),
        FastlaneCore::ConfigItem.new(key: :verbose,
                                     env_name: "MATCH_VERBOSE",
                                     description: "Print out extra information and all commands",
                                     is_string: false,
                                     default_value: false,
                                     verify_block: proc do |value|
                                       $verbose = true if value
                                     end),
        FastlaneCore::ConfigItem.new(key: :android,
                                     env_name: "MATCH_ANDROID",
                                     description: "Use on android platform uses release/debug keystores",
                                     is_string: false,
                                     default_value: false
                                    ),
        FastlaneCore::ConfigItem.new(key: :supply,
                                     env_name: "MATCH_SUPPLY",
                                     description: "work with SUPPLY json keys",
                                     is_string: false,
                                     default_value: false
                                    ),
        FastlaneCore::ConfigItem.new(key: :supply_json_import,
                                     env_name: "MATCH_SUPPLY_IMPORT_PATH",
                                     description: "SUPPLY import json path",
                                     optional: true,
                                     is_string: true,
                                     default_value: false
                                    ),
        FastlaneCore::ConfigItem.new(key: :keystore_password,
                                     env_name: "MATCH_KEYSTORE_PASSWORD",
                                     description: "Password for the Keystore",
                                     optional: true,
                                     is_string: true,
                                     default_value: ""
                                    ),
        FastlaneCore::ConfigItem.new(key: :keystore_alias,
                                     env_name: "MATCH_KEYSTORE_ALIAS",
                                     description: "ALIAS for the Keystore",
                                     optional: true,
                                     is_string: true,
                                     default_value: ""
                                    ),
        FastlaneCore::ConfigItem.new(key: :keystore_destination,
                                     env_name: "MATCH_KEYSTORE_DESTINATION",
                                     description: "Where to put decrypted keystore",
                                     optional: true,
                                     is_string: true,
                                     default_value: ""
                                    ),
        FastlaneCore::ConfigItem.new(key: :supply_destination,
                                     env_name: "MATCH_SUPPLY_DESTINATION",
                                     description: "Where to put decrypted supply key",
                                     optional: true,
                                     is_string: true,
                                     default_value: ""
                                    ),
        FastlaneCore::ConfigItem.new(key: :keystore_fullname,
                                     env_name: "MATCH_KEYSTORE_FULLNAME",
                                     description: "Fullname of keystore owner",
                                     optional: true,
                                     is_string: true,
                                     default_value: ""
                                    ),
        FastlaneCore::ConfigItem.new(key: :keystore_city,
                                     env_name: "MATCH_KEYSTORE_CITY",
                                     description: "City of keystore owner",
                                     optional: true,
                                     is_string: true,
                                     default_value: ""
                                    ),
        FastlaneCore::ConfigItem.new(key: :force,
                                     env_name: "MATCH_FORCE",
                                     description: "Renew the provisioning profiles every time you run match",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :shallow_clone,
                                     env_name: "MATCH_SHALLOW_CLONE",
                                     description: "Make a shallow clone of the repository (truncate the history to 1 revision)",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :workspace,
                                     description: nil,
                                     verify_block: proc do |value|
                                       unless Helper.test?
                                         if value.start_with?("/var/folders") or value.include?("tmp/") or value.include?("temp/")
                                           # that's fine
                                         else
                                           UI.user_error!("Specify the `git_url` instead of the `path`")
                                         end
                                       end
                                     end,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :force_for_new_devices,
                                     env_name: "MATCH_FORCE_FOR_NEW_DEVICES",
                                     description: "Renew the provisioning profiles if the device count on the developer portal has changed",
                                     is_string: false,
                                     default_value: false)
      ]
    end
  end
end
