Before do
  Organisation.current = Organisation.find_by_host("www.example.com")
end

When /^display go to (.+) with "([^\"]*)" params$/ do |page_name, params|
  visit path_to(page_name) + "?#{params}"
end
