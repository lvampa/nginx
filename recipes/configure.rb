#
# Cookbook Name:: cop_nginx
# Recipe:: configure
# Author:: Copious Inc. <engineering@copiousinc.com>
#

directory node['nginx']['vhost_dir'] do
    owner 'root'
    group 'root'
    mode  0755
end

file "#{node['nginx']['vhost_dir']}/default.conf" do
    backup   false
    action   :delete
    notifies :restart, 'service[nginx]', :delayed
    only_if  { node['nginx']['remove_default_site'] }
end

template 'installing compression config' do
    path     '/etc/nginx/compression'
    source   'nginx/compression.erb'
    group    'root'
    owner    'root'
    mode     0644
    backup   5
    action   :create
    notifies :restart, 'service[nginx]', :delayed
end

template 'installing master nginx config' do
    path     '/etc/nginx/nginx.conf'
    source   'nginx/nginx.conf.erb'
    group    'root'
    owner    'root'
    mode     0644
    backup   5
    action   :create
    notifies :restart, 'service[nginx]', :delayed
end

# Check if cop_varnish cookbook is being used
if node.recipe?('cop_varnish::default')
    # Varnish specific vhost template
    vhost_template_source = 'nginx/varnish.conf.erb'
else
    # Standard vhost template
    vhost_template_source = 'nginx/vhost.conf.erb'
end

if node['nginx']['vhosts']
    node['nginx']['vhosts'].each do |vhost, data|
        template "installing #{vhost} nginx vhost" do
            path     "#{node['nginx']['vhost_dir']}/#{vhost}.conf"
            source   vhost_template_source
            group    'root'
            owner    'root'
            mode     0644
            backup   5
            action   :create
            variables ({
                :data => data
            })
            notifies :restart, 'service[nginx]', :delayed
        end
    end
end

service 'nginx' do
    action :enable
    notifies :start, 'service[nginx]', :delayed
end
