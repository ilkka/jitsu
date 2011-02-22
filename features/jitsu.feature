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
        - name: target
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
        - name: hello
          type: executable
          sources:
            - main.cpp
          dependencies:
            - lib.a
        - name: lib.a
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
        - name: lib.so
          type: dynamic_library
          sources:
            - lib.cpp
        - name: blah
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
        - name: lib.la
          type: libtool_library
          sources:
            - lib.cpp
        - name: blah
          type: executable
          sources:
            - main.cpp
          dependencies:
            - lib.la
      """
    When I run jitsu
    And I run "ninja all"
    And I run "libtool --mode=execute ./blah"
    Then the output should be "Hello World" with a newline

  Scenario: Try to run on invalid build.jitsu file
    Given a directory
    And a file "build.jitsu" with contents
    """
    ---
    blah:
      type: executable
      sources:
        - main.cpp
    """
    Then running jitsu should produce an error

  Scenario: Build two executables that share some sources and use same flags
    Given a directory
    And a file "lib.cpp" with contents
      """
      #include "lib.h"

      std::string greeting() {
        return std::string("Hello World");
      }
      """
    And a file "first.cpp" with contents
      """
      #include <iostream>
      
      extern std::string greeting();

      int main(int argc, char* argv[]) {
        std::cout << greeting() << std::endl;
        return 0;
      }
      """
    And a file "second.cpp" with contents
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
        - name: first
          type: executable
          sources:
            - lib.cpp
            - first.cpp
        - name: second
          type: executable
          sources:
            - lib.cpp
            - second.cpp
      """
    When I run jitsu
    And I run "ninja all"
    Then there should be 3 object files in the directory
    And the output of "./first" should be "Hello World" with a newline
    And the output of "./second" should be "Hello World" with a newline
