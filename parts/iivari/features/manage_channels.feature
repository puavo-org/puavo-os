Feature: Manage channels
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Scenario: Create new channel
    Given I am on the new channel page
    When I fill in "Name" with "name 88"
    And I press "Create"
    Then I should see "name 88"
    And I should see "Channel was successfully created."

  Scenario: Change channel name
    Given the following channels:
      |name|
      |name 1|
      |name 2|
      |name 3|
      |name 4|
    And I choose "Edit" link for the 4th channel
    When I fill in "Name" with "name 8"
    And I press "Save"
    Then I should see "name 8"
    And I should see "Channel was successfully updated."

  Scenario: Delete channel
    Given the following channels:
      |name|
      |name 1|
      |name 2|
      |name 3|
      |name 4|
    When I delete the 3rd channel
    Then I should see the following channels:
      |Name|
      |name 1|
      |name 2|
      |name 4|
    And I should see "Channel was successfully destroyed."

