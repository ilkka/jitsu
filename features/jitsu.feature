Feature: Build C++ programs
  In order to build C++ programs
  As a user
  I want to use Jitsu to generate build.ninja files

  Scenario: Build a simple executable
    Given a directory
    And a file "main.cpp" with contents
      """
      #include <iostream>

      int main(int argc, char* argv[]) {
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
    Then the output should be "Hello World" with a newline

  Scenario: Build an executable with a library
    Given a directory
    And a file "lib.cpp" with contents
      """
      #include <iostream>

      void print_hello() {
        std::cout << "Hello World" << std::endl;
      }
      """
    And a file "main.cpp" with contents
      """
      void print_hello();

      int main(int argc, char* argv[]) {
        print_hello();
        return 0;
      }
      """
    And a file "build.jitsu" with contents
      """
      ---
      targets:
        hello:
          type: executable
          sources:
            - main.cpp
          dependencies:
            - lib.a
        lib.a:
          type: static_library
          sources:
            - lib.cpp
      """
    When I run jitsu
    And I run "ninja hello"
    And I run "./hello"
    Then the output should be "Hello World" with a newline

  Scenario: Build a dynamic library
    Given a directory
    And a file "lib.h" with contents
      """
      #include <string>

      std::string greeting();
      """
    And a file "lib.cpp" with contents
      """
      #include "lib.h"

      std::string greeting() {
        return std::string("Hello World");
      }
      """
    And a file "main.cpp" with contents
      """
      #include <iostream>
      
      extern std::string greeting();

      int main(int argc, char* argv[]) {
        std::cout << greeting() << std::endl;
        return 0;
      }
      """
    And a file "build.jitsu" with contents
      """
      ---
      targets:
        lib.so:
          type: dynamic_library
          sources:
            - lib.cpp
        blah:
          type: executable
          sources:
            - main.cpp
          dependencies:
            - lib.so
      """
    When I run jitsu
    And I run "ninja all"
    And I run "env LD_PRELOAD=./lib.so ./blah"
    Then the output should be "Hello World" with a newline

  Scenario: Build an executable using libtool
    Given a directory
    And a file "lib.h" with contents
      """
      #include <string>

      std::string greeting();
      """
    And a file "lib.cpp" with contents
      """
      #include "lib.h"

      std::string greeting() {
        return std::string("Hello World");
      }
      """
    And a file "main.cpp" with contents
      """
      #include <iostream>
      
      extern std::string greeting();

      int main(int argc, char* argv[]) {
        std::cout << greeting() << std::endl;
        return 0;
      }
      """
    And a file "build.jitsu" with contents
      """
      ---
      targets:
        lib.la:
          type: libtool_library
          sources:
            - lib.cpp
        blah:
          type: executable
          sources:
            - main.cpp
          dependencies:
            - lib.la
      """
    When I run jitsu
    And I run "ninja all"
    And I run "env LD_PRELOAD=./lib.so ./blah"
    Then the output should be "Hello World" with a newline

