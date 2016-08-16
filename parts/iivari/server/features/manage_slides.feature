Feature: Manage slides
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Background:
    Given I am logged in as "cucumber" with password "cucumber"
    Given the following channels:
      |name|
      |name 1|
      |name 2|
      |name 3|
      |name 4|
    And I choose "Slides" link for the 1st channel

  Scenario: Register new slide
    Given I follow "New Slide"
    Then I should see "Select slide type"
    When I follow "Text only"
    Then I should see "New slide"
    When I fill in "Title" with "title 1"
    And I fill in "slide_body" with "body 1"
    And I press "Create"
    Then I should see "Slide was successfully created."
    And Slide "title 1" include following information:
    |         |
    | title 1 |
    | body 1  |

  Scenario: Create new slide with external web page
    Given I follow "New Slide"
    Then I should see "Select slide type"
    When I follow "Web page"
    Then I should see "New slide"
    When I fill in "Title" with "Example Web page"
    And I fill in "External Web page URL" with "http://www.opinsys.fi"
    And I press "Create"
    Then I should see "Slide was successfully created."
    And Slide "Example Web page" include following information:
    |                       |
    | http://www.opinsys.fi |

  Scenario: Delete slide
    Given the following slides:
      | title   | body   | template  | channel |
      | title 1 | body 1 | only_text | name 1  |
      | title 2 | body 2 | only_text | name 1  |
      | title 3 | body 3 | only_text | name 1  |
      | title 4 | body 4 | only_text | name 1  |
    And I choose "Slides" link for the 1st channel
    When I follow "Destroy" link for the 3rd slide
    Then I should see "Slide was successfully destroyed."
    And I should see the following slides:
      | title 1 |
      | title 2 |
      | title 4 |

  Scenario: Edit slide content
    Given the following slides:
      | title   | body   | template  | channel |
      | title 1 | body 1 | only_text | name 1  |
      | title 2 | body 2 | only_text | name 1  |
    And I choose "Slides" link for the 1st channel
    When I follow "Edit" link for the 2nd slide
    And I fill in "Title" with "New title"
    And I fill in "slide_body" with "Test slide content"
    Then I press "Save"
    And I should see "Slide was successfully updated."
    
