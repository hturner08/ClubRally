require 'sinatra'
require 'haml'
require 'sinatra/partial'
require 'active_record'
require 'bcrypt'
require 'rest-client'
require 'securerandom'
require 'sinatra/flash'
require 'chronic'
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
        partial :index, :layout => false
    end
end

get "/terms" do
    partial :terms, :layout => false
end

get "/guidelines" do
    partial :guidelines, :layout => false
end

get "/forgot" do
    partial :wip, :layout => false
end

get "/dashboard/home" do
    $path = "/dashboard/home"
    protected!
    startup
    @clubs = []
    @user.clubs.each do |club|
        @clubs << Club.find_by(:name => club)
    end
    partial :dashboard_home, :layout => false
end

get "/dashboard/browse" do
    $path = "/dashboard/browse"
    protected!
    startup
    @clubs = Club.where(:approved => true)
    partial :dashboard_browse, :layout => false
end

error do
    partial :servererror, :layout => false
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
        if approved?(club) and all_data.downcase.include? query
            @clubs.push(club)
        end
    end
    partial :dashboard_search, :layout => false
end

#DB
get "/debug/dbinit" do
    dbinit
    redirect "/"
end

def dbinit
    ActiveRecord::Migration.class_eval do
        if User.table_exists?
            drop_table :users
        end 
        if Club.table_exists?
            drop_table :clubs
        end 
        if Admin.table_exists?
            drop_table :admins
        end
        create_table :users do |t|
            t.string :email
            t.string :salt
            t.string :passwordhash
            t.boolean :verified
            t.string :verification_code
            t.string :notifications
            t.integer :notification_id
            t.string :clubs, array: true
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
            t.boolean :approved
            t.boolean :nomeeting
            t.string :website
        end
        create_table :admins do |t|
            t.string :email
        end
        Admin.create(:email => "jshen@andover.edu")
        #Admin.create(:email => "jshen1@andover.edu")
        #Admin.create(:email => "ali2@andover.edu")
        #Admin.create(:email => "scdavis@andover.edu")
        #Admin.create(:email => "hturner@andover.edu")
        #Admin.create(:email => "awang1@andover.edu")
    end
end
