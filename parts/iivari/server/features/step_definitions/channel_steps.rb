Given /^the following channels:$/ do |channels|
  Channel.create!(channels.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) channel$/ do |pos|
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following channels:$/ do |expected_channels_table|
  expected_channels_table.diff!(tableish('table tr', 'td,th'))
end

When /^I choose "([^\"]*)" link for the (\d+)(?:st|nd|rd|th) channel$/ do |link_name, pos|
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link link_name
  end
end

Given /^I am logged in as "([^\"]*)" with password "([^\"]*)"$/ do |login, password|
  visit new_user_session_path
  fill_in("user_session_login", :with => login)
  fill_in("user_session_password", :with => password)
  click_button("Login")
  page.should have_content("Logged in as " + login)
end
