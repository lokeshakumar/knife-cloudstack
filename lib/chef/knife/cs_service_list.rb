#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2011 Edmunds, Inc.
# Copyright:: Copyright (c) 2013 Sander Botman.
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

require 'chef/knife/cs_base'
require 'chef/knife/cs_baselist'

module KnifeCloudstack
  class CsServiceList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase
    include Chef::Knife::KnifeCloudstackBaseList

    deps do
      require 'chef/knife'
      require 'knife-cloudstack/connection'
      Chef::Knife.load_deps
    end

    banner "knife cs service list (options)"

    option :name,
           :long => "--name NAME",
           :description => "Specify servicename to list"

    option :keyword,
           :long => "--keyword NAME",
           :description => "Specify part of servicename to list"

    option :index,
           :long => "--index",
           :description => "Add index numbers to the output",
           :boolean => true

    def run
      validate_base_options
	
      object_list = []
      object_list << ui.color('Index', :bold) if locate_config_value(:index)

      if locate_config_value(:fields)
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        [
          ui.color('Name', :bold),
          ui.color('Memory', :bold),
          ui.color('CPUs', :bold),
          ui.color('CPU Speed', :bold),
          ui.color('Created', :bold)
        ].each { |field| object_list << field }
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_object(
        "listServiceOfferings",
        "serviceoffering",
        locate_config_value(:filter),
        false,
        locate_config_value(:keyword),
        locate_config_value(:name)
      )

      output_format(connection_result)
 
      index_num = 0
      connection_result.each do |r|
        if locate_config_value(:index)
          index_num += 1
          object_list << index_num.to_s
        end

        if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << r['name'].to_s
          object_list << (r['memory'] ? human_memory(r['memory']) : 'Unknown')
          object_list << r['cpunumber'].to_s
          object_list << r['cpuspeed'].to_s + ' Mhz'
          object_list << r['created']
        end
      end
      puts ui.list(object_list, :uneven_columns_across, columns)
      list_object_fields(connection_result) if locate_config_value(:fieldlist)
    end

    def human_memory n
      count = 0
      while  n >= 1024 and count < 2
        n /= 1024.0
        count += 1
      end
      format("%.0f", n) + %w(MB GB TB)[count]
    end

  end
end
