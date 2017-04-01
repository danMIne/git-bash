#!/usr/bin/env ruby

# choice consts
INNER_ESB_TAG = "inner"
OUTER_ESB_TAG = "outer"
WEBAPI_TAG = "wapi"

# pattern const
INNER_TAG_PATTERN = /^v-in.+$/
OUTER_TAG_PATTERN = /^v-ext.+$/
WEBAPI_TAG_PATTERN = /^v-wp.+$/

# prefix const
INNER_ESB_PREFIX = "v-in."
OUTER_ESB_PREFIX = "v-ext."
WEBAPI_PREFIX = "v-wp."

def get_tags
  repo_url = "git@gitlab.beisencorp.com:pps/Beisen.CoreHrV5.git"
  tags_ori = `git ls-remote -t --refs`
  tags = tags_ori.split("\n")
  tags.each do |tag|
    tag.gsub!(/^\w+\s+refs\/tags\//,"")
  end
  return tags
end

def filter_tags_by_choice(choice, tags)
  if choice.eql? INNER_ESB_TAG
    pattern = INNER_TAG_PATTERN
  elsif choice.eql? OUTER_ESB_TAG
    pattern = OUTER_TAG_PATTERN
  elsif choice.eql? WEBAPI_TAG
    pattern = WEBAPI_TAG_PATTERN
  end
  return tags.select{|o| pattern.match o}
end

def get_current_version(tags)
  max = 0
  tags.each do |tag|
    tag_split = tag.split(".")
    # Higher position code got a greater power
    num = tag_split[1].to_i * 1000 + tag_split[2].to_i
    if max < num
      max = num
    end
  end
  return  max/1000, max%1000
end

def get_next_version(tags, up)
  version = get_current_version tags
  if up
    return [version[0] + 1, 0]
  else
    return [version[0], version[1] + 1]
  end  
end

def get_current_tag(choice)
  tags = get_tags()
  tags = filter_tags_by_choice(choice, tags) 
  num = get_current_version(tags)
  
  tags.each do |tag|
    tag_split = tag.split(".")
    if ((tag_split[1].to_i == num[0]) & (tag_split[2].to_i == num[1]))
      return tag
    end
  end
  
  return nil
end

def create_tag(choice, message, up)
  tags = get_tags
  num = get_next_version(tags, up)
  
  suffix = num[0].to_s + "." + num[1].to_s
  if choice == INNER_ESB_TAG
    tag = INNER_ESB_PREFIX + suffix
  elsif choice == OUTER_ESB_TAG
    tag = OUTER_ESB_PREFIX + suffix
  elsif choice == WEBAPI_PREFIX
    tag = WEBAPI_PREFIX + suffix
  else
    return
  end
  `git tag #{tag} -m "#{message}"`
  `git push origin #{tag}`
end

def get_default_commit
    committer = `git config --get user.name`
	commit = "New hotfix by #{committer.chomp} -- #{Time.now.strftime("%Y-%m-%d")}"
	return commit
end

def hf_create(choice, b_name)
  tag = get_current_tag(choice)
  if(tag == nil)
	p "Warn: No tag found for #{choice} choice!"
	return
  end
  `git fetch -p`
  system "git checkout #{tag}"
  if b_name.eql?(nil)
    b_name = "hotfix-" + Time.now.strftime("%Y%m%d") + "_" + rand(36**3).to_s(36) 
  end
  `git stash`
  system "git checkout -b #{b_name}"
end

def hf_submit(choice, commit, up)  
  if(commit != nil)
    `git add .`
    `git commit --allow-empty -m "#{commit}"`
	message = commit
  else
    message = get_default_commit
  end
  create_tag choice, commit, up
end

def validate_args(args)
  if args.count < 2
    p "ERROR: Arguments required"
	return 0
  elsif !["-c","-s"].include? args[0]
    p "ERROR: Unknow option #{args[0]}"
	return 0
  elsif ![INNER_ESB_TAG, OUTER_ESB_TAG, WEBAPI_TAG].include? args[1]
    p "ERROR: Unknow project #{args[1]}"
	return 0
  elsif args[0] == "-c"
    return 1
  elsif args[0] == "-s"
    return 2
  end  
end

def execute(args)
  dep = validate_args(args)
  if dep == 1
    if args[2] == "-b"
	  b_name = args[3]
	end
	hf_create args[1], args[3]
  elsif dep == 2
    if args[2] == "-m"
	  commit = args[3]
	  if [nil, "-p"].include? commit	
		commit = get_default_commit
	  end
	end
    hf_submit args[1], commit, (args[-1] == "-p")
  end
end

execute ARGV
