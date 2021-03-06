<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=no, viewport-fit=cover">
    <title>Flow & Grow</title>

    <!-- index.css needs to be the first stylesheet. -->
    <link href="assets/css/index.css?a=<?php echo time() ?>" rel="stylesheet">
    <script src="assets/js/index.js?a=<?php echo time() ?>"></script>

    <link href="https://fonts.googleapis.com/css?family=Montserrat:400,600" rel="stylesheet">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.2.0/css/all.css" integrity="sha384-hWVjflwFxL6sNzntih27bfxkr27PmbbK/iSvJ+a4+0owXq79v+lsFkW54bOGbiDQ" crossorigin="anonymous">

  </head>
  <body>

    <div id="container">

      <div id="content">

        <div id="hint">
          <i class="fas fa-info-circle"></i>&nbsp;<span>Tip: Gebruik je muis om de mindmap te verslepen.</span>
        </div>

        <button id="zoom-in-button" class="zoom-button">
          <i class="fas fa-search-plus"></i>
        </button>

        <button id="zoom-out-button" class="zoom-button">
          <i class="fas fa-search-minus"></i>
        </button>


        <img id="logo" src="assets/images/logo.png">

        <div id="mindmap">
          <ol id="leftbranch" class="children leftbranch">
          </ol>

          <div id="rootnode" class="node">

            <div class="textbubble">
              <span class="textBubbleContent loading">
                <label>Aan het laden...</label>
                <div class="loadingRing">
                  <div></div>
                </div>
              </span>
            </div>

            <img src="assets/images/root.png">

            <button id="reset-button" class="no-drag">
              Reset&nbsp;&nbsp;<i class="fas fa-redo"></i>
            </button>
          </div>

          <ol id="rightbranch" class="children rightbranch">
          </ol>
        </div>

        <button id="reset-position-button" class="no-drag">
          Centreren&nbsp;&nbsp;<i class="fas fa-arrows-alt"></i>
        </button>

        <div id="footer">
          <h3>UvA Flow & Grow</h3><br>
          <h4>&copy; 2019 Universiteit van Amsterdam | <a href="#privacy" id="privacy-button">Privacy</a></h4>
        </div>

        <div id="privacy-popup">
        <h2>Privacy Policy</h2>
        <span>
          <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>

          <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>

          <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>

          <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>

          <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
          <button id="accept-button">OK&nbsp;&nbsp;<i class="fas fa-check"></i></button>
        </span>
      </div>


      </div>

    </div>
    <span id="text-ruler"></span>
  </body>
</html>
