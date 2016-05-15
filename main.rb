require 'sinatra'
require 'haml'
require 'sinatra/partial'
require 'active_record'
require 'bcrypt'
require 'rest_client'
require 'securerandom'
require './db/config.rb'
require './user.rb'
require './rb/auth.rb'
require './rb/feed.rb'
require './rb/club.rb'

enable :sessions

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

get "/dashboard/home" do
    $path = "/dashboard/home"
    protected!
    startup
    @clubs = []
    Club.all.each do |club|
        if club.members.include? session[:username] or club.head.include? session[:username]
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

get "/verify" do
    if login? 
        redirect $path
    end
    
    partial :verify, :layout => false
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
        all_data = "#{club.name} #{club.description}"
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
            t.string :meetingday
            t.string :location
        end
    end
end
