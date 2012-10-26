#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
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
    module Unix

      def current_owner
        case new_resource.owner
        when String, nil
          lookup_uid
        when Integer
          stat.uid
        else
          Chef::Log.error("The `owner` parameter of the #@new_resource resource is set to an invalid value (#{new_resource.owner.inspect})")
          raise ArgumentError, "cannot resolve #{new_resource.owner.inspect} to uid, owner must be a string or integer"
        end
      end
  
      def lookup_uid
        unless (pwent = Etc.getpwuid(stat.uid)).nil?
          pwent.name
        else
          stat.uid
        end
      rescue ArgumentError
        stat.uid
      end
  
      def current_group
        case new_resource.group
        when String, nil
          lookup_gid
        when Integer
          stat.gid
        else
          Chef::Log.error("The `group` parameter of the #@new_resource resource is set to an invalid value (#{new_resource.owner.inspect})")
          raise ArgumentError, "cannot resolve #{new_resource.group.inspect} to gid, group must be a string or integer"
        end
      end
  
      def lookup_gid
        unless (pwent = Etc.getgrgid(stat.gid)).nil?
          pwent.name
        else
          stat.gid
        end
      rescue ArgumentError
        stat.gid
      end
  
      def current_mode
        case new_resource.mode
        when String, nil
          (stat.mode & 007777).to_s(8)
        when Integer
          stat.mode & 007777
        else
          Chef::Log.error("The `mode` parameter of the #@new_resource resource is set to an invalid value (#{new_resource.mode.inspect})")
          raise ArgumentError, "Invalid value #{new_resource.mode.inspect} for `mode` on resource #@new_resource"
        end
      end
  
      def stat
        @stat ||= @new_resource.instance_of?(Chef::Resource::Link) ? ::File.lstat(@new_resource.path) : ::File.stat(@new_resource.path)
      end
    end
  end
end
