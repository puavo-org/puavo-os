Feature: Manage channels
  In order to [goal]
  [stakeholder]
  wants [behaviour]

  Background:
    Given I am logged in as "cucumber" with password "cucumber"
    And I follow "Example school"
  
  Scenario: Create new channel
    Given I follow "New Channel"
    When I fill in "Name" with "name 88"
    And I press "Create"
    Then I should see "name 88"
    And I should see "Channel was successfully created."

  Scenario: Change channel name
    Given the following channels:
      | name   | slide_delay | school_id |
      | name 1 |          15 |         1 |
      | name 2 |          15 |         1 |
      | name 3 |          15 |         1 |
      | name 4 |          15 |         1 |
    And I follow "Channels"
    And I choose "Edit" link for the 4th channel
    When I fill in "Name" with "name 8"
    And I press "Save"
    Then I should see "name 8"
    And I should see "Channel was successfully updated."

  Scenario: Delete channel
    Given the following channels:
      | name   | slide_delay | school_id |
      | name 1 |          15 |         1 |
      | name 2 |          15 |         1 |
      | name 3 |          15 |         1 |
      | name 4 |          15 |         1 |
    And I follow "Channels"
    When I delete the 3rd channel
    Then I should see the following channels:
      |Name|
      |name 1|
      |name 2|
      |name 4|
    And I should see "Channel was successfully destroyed."

