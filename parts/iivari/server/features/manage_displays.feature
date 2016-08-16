Feature: Manage displays
  In order to [goal]
  [stakeholder]
  wants [behaviour]

  Background:
    Given the following channels:
      | name         |
      | Main channel |
    Given the following slides:
      | title   | body   | template  | channel      |
      | title 1 | body 1 | only_text | Main channel |
      | title 2 | body 2 | only_text | Main channel |
    And I am logged in as "cucumber" with password "cucumber"

  Scenario: Register new display
    When display go to the display authentication page with "hostname=test1&resolution=800x600" params
    #And display go to the conductor page with "hostname=test1&resolution=800x600" params
    And display go to the conductor slides page with "hostname=test1&resolution=800x600" params
    Then display should see "To activate the display and select a channel"
    When I am on the displays page
    Then I should see "test1"
    When I follow "test1"
    Then I should see "Active: false"
    And I should see "Channel: Not selected"
    And I should see "Hostname: test1"
    When I follow "Edit"
    And I select "Main channel" from "Channel"
    And I check "Active"
    And I press "Save"
    #When display go to the conductor page with "hostname=test1&resolution=800x600" params
    When display go to the conductor slides page with "hostname=test1&resolution=800x600" params
    Then display should see "title 1"
    And display should see "body 1"

  Scenario: Display authentication
    When display go to the conductor slides page with "hostname=test1&resolution=800x600" params
    Then display should see "Unauthorized"
    When display go to the display authentication page with "hostname=test1&resolution=800x600" params
    Then display should be on the conductor screen page
    When display go to the conductor slides page with "hostname=test1&resolution=800x600" params
    Then display should see "To activate the display and select a channel"

  # Rails generates Delete links that use Javascript to pop up a confirmation
  # dialog and then do a HTTP POST request (emulated DELETE request).
  #
  # Capybara must use Culerity/Celerity or Selenium2 (webdriver) when pages rely
  # on Javascript events. Only Culerity/Celerity supports clicking on confirmation
  # dialogs.
  #
  # Since Culerity/Celerity and Selenium2 has some overhead, Cucumber-Rails will
  # detect the presence of Javascript behind Delete links and issue a DELETE request 
  # instead of a GET request.
  #
  # You can turn this emulation off by tagging your scenario with @no-js-emulation.
  # Turning on browser testing with @selenium, @culerity, @celerity or @javascript
  # will also turn off the emulation. (See the Capybara documentation for 
  # details about those tags). If any of the browser tags are present, Cucumber-Rails
  # will also turn off transactions and clean the database with DatabaseCleaner 
  # after the scenario has finished. This is to prevent data from leaking into 
  # the next scenario.
  #
  # Another way to avoid Cucumber-Rails' javascript emulation without using any
  # of the tags above is to modify your views to use <button> instead. You can
  # see how in http://github.com/jnicklas/capybara/issues#issue/12
  #
#  Scenario: Delete display
#    Given the following displays:
#      |status|channel|hostname|
#      |status 1|channel 1|hostname 1|
#      |status 2|channel 2|hostname 2|
#      |status 3|channel 3|hostname 3|
#      |status 4|channel 4|hostname 4|
#    When I delete the 3rd display
#    Then I should see the following displays:
#      |Status|Channel|Hostname|
#      |status 1|channel 1|hostname 1|
#      |status 2|channel 2|hostname 2|
#      |status 4|channel 4|hostname 4|
#
