#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/knife'
require 'chef/node'
require 'chef/search/query'
require 'chef/json_compat'

class Chef
  class Knife

    class NodeEdit < Knife

      deps do
        require 'chef/node'
        require 'chef/json_compat'
        require 'chef/knife/core/node_editor'
      end

      banner "knife node edit NODE (options)"

      option :all_attributes,
        :short => "-a",
        :long => "--all",
        :boolean => true,
        :description => "Display all attributes when editing"

      def run
        if node_name.nil?
          show_usage
          ui.fatal("You must specify a node name")
          exit 1
        end

        begin
          edit_object(Chef::Node, @node_name)
        rescue Chef::Exceptions::NodeNotFound
          # We didn't find it, look for a node with the name set
          # to what we've been asked to edit
          begin
            q = Chef::Search::Query.new
            nodes = q.search(:node, "name:#{@node_name}*")
            if nodes[0].length == 1
              edit_object(Chef::Node, nodes[0][0].name)
            else
              node = ask_select_option("Which node do you want to edit?", nodes[0])
              edit_object(Chef::Node, node.name)
            end
          rescue NoMethodError
            raise Chef::Exceptions::NodeNotFound, "Node #{@node_name} not found"
          end
        end
      end

      def node_name
        @node_name ||= @name_args[0]
      end

      def node_editor
        @node_editor ||= Knife::NodeEditor.new(node, ui, config)
      end

      def node
        @node ||= Chef::Node.load(node_name)
      end

    end
  end
end


