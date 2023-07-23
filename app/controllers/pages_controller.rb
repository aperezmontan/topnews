class PagesController < ApplicationController

  def home
    # TODO: make sure you handle errors here
    story_ids = call_api("https://hacker-news.firebaseio.com/v0/topstories.json")

    # TODO: put a caching mechanism here for efficiency if time permits
    non_persisted_stories = story_ids.map(&:to_s) - Story.where(story_id: story_ids).pluck(:story_id)
    non_persisted_stories.first(10).each { |story_id| create_story(story_id) }

    @stories = Story.includes(starrables: :user).where(story_id: story_ids)
    @current_user_stories = @stories.joins(:starrables).where(starrables: {user_id: current_user.id})
  end

  private

  def create_story(story_id)
    story_response = call_api("https://hacker-news.firebaseio.com/v0/item/#{story_id}.json")
    params = create_story_params(story_response)
    Story.create!(params)
  end

  def create_story_params(res)
    params = res.slice("by", "id", "score", "time", "title", "url")
    params["author"] = params.delete("by")
    params["story_id"] = params.delete("id")
    params["time"] = Time.at(params.delete("time")).to_datetime
    params
  end

  def call_api(url)
    uri = URI(url)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end
