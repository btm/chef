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
  # == ScanAccessControl
  # Reads Access Control Settings on a file and writes them out to a resource
  # (should be the current_resource), attempting to match the style used by the
  # new resource, that is, if users are specified with usernames in
  # new_resource, then the uids from stat will be looked up and usernames will
  # be added to current_resource.
  #
  # === Why?
  # FileAccessControl objects may operate on a temporary file, in which case we
  # won't know if the access control settings changed (ex: rendering a template
  # with both a change in content and ownership). For auditing purposes, we
  # need to record the current state of a file system entity.
  #--
  # Not yet sure if this is the optimal way to solve the problem. But it's
  # progress towards the end goal.
  #
  # TODO: figure out if all this works with OS X's negative uids
  # TODO: windows
  class ScanAccessControl

    attr_reader :new_resource
    attr_reader :current_resource

    if RUBY_PLATFORM =~ /mswin|mingw|windows/
      require 'chef/scan_access_control/windows'
      include ScanAccessControl::Windows
    else
      require 'chef/scan_access_control/unix'
      include ScanAccessControl::Unix
    end

    def initialize(new_resource, current_resource)
      @new_resource, @current_resource = new_resource, current_resource
    end

    # Modifies @current_resource, setting the current access control state.
    def set_all!
      if ::File.exist?(new_resource.path)
        set_owner
        set_group
        set_mode unless Chef::Platform.windows?
      else
        # leave the values as nil.
      end
    end

    # Set the owner attribute of +current_resource+ to whatever the current
    # state is. Attempts to match the format given in new_resource: if the
    # new_resource specifies the owner as a string, the username for the uid
    # will be looked up and owner will be set to the username, and vice versa.
    def set_owner
      @current_resource.owner(current_owner)
    end

    # Set the group attribute of +current_resource+ to whatever the current state is.
    def set_group
      @current_resource.group(current_group)
    end

    def set_mode
      @current_resource.mode(current_mode)
    end
  end
end
