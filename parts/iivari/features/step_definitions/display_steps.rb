Given /^the following displays:$/ do |displays|
  Display.create!(displays.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) display$/ do |pos|
  visit displays_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

When /^I follow "([^\"]*)" link for the (\d+)(?:st|nd|rd|th) display$/ do |link_name, pos|
  visit displays_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following displays:$/ do |expected_displays_table|
  expected_displays_table.diff!(tableish('table tr', 'td,th'))
end

Then /^display should see "([^"]*)"(?: within "([^"]*)")?$/ do |text, selector|
  steps %Q{ Then I should see "#{text}" }
end

Then /^display should be on (.+)$/ do |page_name|
  steps %Q{ Then I should be on #{page_name} }
end
