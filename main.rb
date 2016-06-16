require 'sinatra'
require 'haml'
require 'sinatra/partial'
require 'active_record'
require 'bcrypt'
require 'rest-client'
require 'securerandom'
require './db/config.rb'
require './user.rb'
require './rb/auth.rb'
require './rb/feed.rb'
require './rb/club.rb'

enable :sessions

$footer = [{:path => "/terms", :text => "TERMS OF SERVICE"}, {:path => "https://docs.google.com/forms/d/1mtfMw_Ok2Wxs8SiRH8poPpYui1emb-YeGUjkG6voIwM/viewform", :text => "REPORT A BUG"}, {:path => "mailto:jshen@andover.edu", :text => "CONTACT"}]

def startup
    @user = User.find_by(email: session[:username])
    time = Time.new
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    Club.all.each do |club|
        if clubincludesuser?(club)
            @user.notifications.delete_if { |h| h[:title] == club.name}
            clubday = days.index(club.meetingtime.split(',')[0])
            if (clubday > time.wday and clubday - 2 < time.wday) or (clubday <= 1 and (time.wday > 5 or time.wday == 0))
                send_notification(@user, "clock-o", club.name, "#{club.meetingtime}, #{club.location}")
            end
        end
    end
end

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
    @clubs = Club.where(:approved => true)
    partial :dashboard_browse, :layout => false
end

#debug
get "/debug/dbinit" do 
    dbinit
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
        if approved?(club) and all_data.downcase.include? query
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
