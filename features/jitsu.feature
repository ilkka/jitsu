Feature: Build C++ programs
  In order to build C++ programs
  As a user
  I want to use Jitsu to generate build.ninja files

  Scenario: Build a simple executable
    Given a directory
    And a file "main.cpp" with contents
      """
      #include <iostream>

      int main(int argc. char* argv[]) {
        std::cout << "Hello World" << std::endl;
        return 0;
      }
      """
    And a file "build.jitsu" with contents
      """
      ---
      targets:
        target:
          type: executable
          sources:
            - main.cpp
      """
    When I run jitsu
    And I run "ninja target"
    And I run "./target"
    Then the output should be "Hello world"
