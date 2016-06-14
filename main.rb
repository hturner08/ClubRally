require 'sinatra'
require 'haml'
require 'sinatra/partial'
require 'active_record'
require 'bcrypt'
require 'rest_client'
require 'securerandom'

configure { set :server, :puma }

require './db/config.rb'
require './user.rb'
require './rb/auth.rb'
require './rb/feed.rb'
require './rb/club.rb'

enable :sessions

$footer = [{:path => "/terms", :text => "TERMS OF SERVICE"}, {:path => "https://docs.google.com/forms/d/1mtfMw_Ok2Wxs8SiRH8poPpYui1emb-YeGUjkG6voIwM/viewform", :text => "REPORT A BUG"}, {:path => "mailto:jshen@andover.edu", :text => "CONTACT"}]

get "/" do 
    if login? 
        startup
        redirect "/dashboard/home"
    else
        $error = nil
        $register_error = nil
        partial :index, :layout => false
    end
end

get "/terms" do
    partial :terms, :layout => false
end

get "/forgot" do
    partial :wip, :layout => false
end

get "/dashboard/home" do
    $path = "/dashboard/home"
    protected!
    startup
    @clubs = []
    Club.all.each do |club|
        if clubincludesuser?(club)
            @clubs << club
        end
    end
    partial :dashboard_home, :layout => false
end

get "/dashboard/browse" do
    $path = "/dashboard/browse"
    protected!
    startup
    @clubs = Club.all
    partial :dashboard_browse, :layout => false
end

get "/debug/dbinit" do 
    dbinit
    redirect "/"
end

get "/debug/mail" do
    send_simple_message
    redirect "/"
end

get "/debug/random" do
    puts SecureRandom.hex
    redirect "/"
end

not_found do
    status 404
    partial :oops, :layout => false
end

get "/404" do
    partial :oops, :layout => false
end

get "/dashboard/search" do
    $path = "/dashboard/search?search=#{params[:search]}" 
    protected!
    startup
    query = params[:search].downcase
    @clubs = []
    Club.all.each do |club|
        all_data = "#{club.name} #{club.description} #{club.tag}"
        if all_data.downcase.include? query
            @clubs.push(club)
        end
    end
    partial :dashboard_search, :layout => false
end

def dbinit
    ActiveRecord::Migration.class_eval do
        if User.table_exists?
            drop_table :users
        end 
        if Club.table_exists?
            drop_table :clubs
        end 
        create_table :users do |t|
            t.string :email
            t.string :salt
            t.string :passwordhash
            t.boolean :verified
            t.string :verification_code
            t.string :notifications
            t.integer :notification_id
        end
        create_table :clubs do |t|
            t.string :name
            t.string :description
            t.string :head, array: true
            t.string :board, array: true
            t.string :img
            t.string :members, array: true
            t.string :meetingtime
            t.string :location
            t.string :tag
        end
    end
end
