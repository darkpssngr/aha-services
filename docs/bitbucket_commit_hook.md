This integration will create a comment in Aha! each time a feature or
requirement is referenced in a [Bitbucket](http://www.bitbucket.org/) commit message.

Installation
------------

1. On the _Settings_ tab of the Bitbucket repository, open the _Hooks_ section.
2. Select _POST_ and click _Add hook_.
3. Paste the payload URL from _Hook URL_ section in the URL box.
4. Enable this integration below.

Usage
-----

Each commit message to the Bitbucket repository will be processed. If the
commit message contains the reference from an Aha! feature or requirement
then the commit message will be added as a comment to the feature or
requirement. The reference can be anywhere in the commit message, e.g. a
commit message like:

    Corrected typo, fixes APP-343.

would add a comment to the feature APP-343.
