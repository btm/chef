#--
# Author:: Bryan McLellan (<btm@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

class Chef
  class ScanAccessControl
    module Windows

      def current_owner
        case new_resource.owner
        when String, nil
          so.owner
        else
          Chef::Log.error("The `owner` parameter of the #@new_resource resource is set to an invalid value (#{new_resource.owner.inspect})")
          raise ArgumentError, "cannot resolve #{new_resource.owner.inspect} to a sid, owner must be a string"
        end
      end
  
      def current_group
        case new_resource.group
        when String, nil
          so.group
        else
          Chef::Log.error("The `group` parameter of the #@new_resource resource is set to an invalid value (#{new_resource.group.inspect})")
          raise ArgumentError, "cannot resolve #{new_resource.group.inspect} to sid, group must be a string"
        end
      end
  
      # TODO: current_dacl

      def current_mode
        nil
      end
  
      def so
        @so ||= Chef::ReservedNames::Win32::Security.get_named_security_info(@new_resource.path)
      end
    end
  end
end
