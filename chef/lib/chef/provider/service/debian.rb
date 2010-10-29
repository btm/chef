#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/provider/service'
require 'chef/provider/service/init'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Debian < Chef::Provider::Service::Init
        UPDATE_RC_D_ENABLED_MATCHES = /etc\/rc[\dS].d\/S|not installed/i
        UPDATE_RC_D_PRIORITIES = /etc\/rc([\dS]).d\/([SK])(\d\d)/i

        def load_current_resource
          super

          @current_resource.enabled(service_currently_enabled?)
          @current_resource
        end

        def assert_update_rcd_available
          unless ::File.exists? "/usr/sbin/update-rc.d"
            raise Chef::Exceptions::Service, "/usr/sbin/update-rc.d does not exist!"
          end
        end

        def service_currently_enabled?
          assert_update_rcd_available

          status = popen4("/usr/sbin/update-rc.d -n -f #{@current_resource.service_name} remove") do |pid, stdin, stdout, stderr|
            priority = {}
            enabled = false

            stdout.each_line do |line|
              if UPDATE_RC_D_PRIORITIES =~ line
                priority[$1] = [($2 == "S" ? :start : :stop), $3]
              end
              if line =~ UPDATE_RC_D_ENABLED_MATCHES
                enabled = true
              end
            end
            @current_resource.enabled enabled
            @current_resource.priority priority
          end

          unless status.exitstatus == 0
            raise Chef::Exceptions::Service, "/usr/sbin/update-rc.d -n -f #{@current_resource.service_name} failed - #{status.inspect}"
          end
          @current_resource.enabled
        end

        def enable_service()
          # clean up any latent links
          run_command(:command => "/usr/sbin/update-rc.d -f #{@new_resource.service_name} remove")

          # If we have a priority which is just a number, we have to
          # construct the actual priority object

          if @new_resource.priority.is_a? Integer
            run_command(:command => "/usr/sbin/update-rc.d #{@new_resource.service_name} defaults #{@new_resource.priority} #{100 - @new_resource.priority}")
          elsif @new_resource.priority.is_a? Hash
            # we call the same command regardless of we're enabling or disabling  
            # users passing a Hash are responsible for setting their own start priorities
            set_priority()
          else # No priority, go with update-rc.d defaults
            run_command(:command => "/usr/sbin/update-rc.d #{@new_resource.service_name} defaults")
          end

        end

        def disable_service()
          # clean up any latent links
          run_command(:command => "/usr/sbin/update-rc.d -f #{@new_resource.service_name} remove")

          if @new_resource.priority.is_a? Integer
            # Stop processes in reverse order of start using '100 - start_priority'
            run_command(:command => "/usr/sbin/update-rc.d -f #{@new_resource.service_name} stop #{100 - @new_resource.priority} 2 3 4 5 .")
          elsif @new_resource.priority.is_a? Hash
            # we call the same command regardless of we're enabling or disabling  
            # users passing a Hash are responsible for setting their own stop priorities
            set_priority()
          else 
            # no priority, using '100 - 20 (update-rc.d default)' to stop in reverse order of start
            run_command(:command => "/usr/sbin/update-rc.d -f #{@new_resource.service_name} stop 80 2 3 4 5 .")
          end
        end

        def set_priority()
          args = ""
          @new_resource.priority.each do |level, o|
            action = o[0]
            priority = o[1]
            args += "#{action} #{priority} #{level} . "
          end
          run_command(:command => "/usr/sbin/update-rc.d -f #{@new_resource.service_name} remove")
          run_command(:command => "/usr/sbin/update-rc.d #{@new_resource.service_name} #{args}")
        end
      end
    end
  end
end
