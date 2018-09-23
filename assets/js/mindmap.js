// SET THIS TO THE ENDPOINT THAT PROVIDES THE MINDMAP-DATA.
var DATA_ENDPOINT = "data/content.json"

/*
 * Used to store the JSON, the calculated width and height of nodes
 * and to block any mouse-actions while the privacy-popup is open.
 */
var jsondata, nodewidth, nodeheight;
var mousedisabled = false;

/*
 * Toggle for editor-mode.
 * Gets overriden by the editor script.
 */
var editormode = false;

$(function(){
  bindPanHandler();
  bindButtonClickHandlers();
  initialize();
});

/*
 * Loads the content stored in data/content.json, adds functionality
 * to the dropdown and passes the JSON to loadMindmap when the user
 * has selected a study and year.
 */
function initialize() {
  $.getJSON(DATA_ENDPOINT + "?" + Math.floor(Math.random() * 1000000), function(json){
    jsondata = json;
    var studies = Object.keys(jsondata.content);
    var sortedStudies = studies.concat().sort(function(a, b){
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    });

    var studySelect = $("#studySelect");
    var yearSelect = $("#yearSelect");

    $.each(sortedStudies, function(index, value) {
      studySelect[0].add(new Option(value, studies.indexOf(value)));
    });
    if (editormode) {
      studySelect[0].add(new Option("Studie toevoegen...", "new"));
      yearSelect[0].add(new Option("Nieuw studiejaar...", "new"));
      yearSelect.prop("disabled", false);
    }

    // Picks the right year-options when a different study has been selected.
    studySelect.change(function() {
      if (this.value == "new") {
        addNewStudy();
      } else {
        var yearOptions = Object.keys(jsondata.content[studies[this.value]]);
        var sortedYearOptions = yearOptions.concat().sort(function(a, b){
            if (a < b) return -1;
            if (a > b) return 1;
            return 0;
        });

        if (yearOptions.length > 0) {
          yearSelect.prop("disabled", false);
        } else {
          yearSelect.prop("disabled", true);
        }

        yearSelect.find("option").not(':first').remove();
        $.each(sortedYearOptions, function(index, value) {
          yearSelect[0].add(new Option(value, yearOptions.indexOf(value)));
        })
        if (editormode) {
          yearSelect[0].add(new Option("Nieuw studiejaar...", "new"));
        }
        yearSelect.val("");
      }
    });

    yearSelect.change(function() {
      if (this.value == "new") {
        addNewYear();
      } else if (this.value != "") {
        $("#loadMindmapButton").prop("disabled", false);
      } else {
        $("#loadMindmapButton").prop("disabled", true);
      }
    });

    // Load the mindmap when the configuration has been selected.
    $("#loadMindmapButton").click(function() {
      loadMindmap(studySelect.val(), yearSelect.val());
    });
  });
}

/*
 * Binds the pan-handler to the mindmap that allows the user
 * to pan around the mindmap.
 */
function bindPanHandler() {
  var clicking = false;
  var previousX;
  var previousY;

  document.addEventListener('touchstart', function(e) {
    if (e.touches.length !== 1) { return }
    previousX = e.targetTouches[0].pageX;
    previousY = e.targetTouches[0].pageY;
    clicking = true;
  });

  document.addEventListener('touchend', function(e) {
    clicking = false;
  });

  document.addEventListener('touchmove', function(e) {
    if (e.touches.length !== 1) { return }
    if (clicking && !mousedisabled) {
      var directionX = previousX - e.targetTouches[0].pageX;
      var directionY = previousY - e.targetTouches[0].pageY;
      var oldPosition = $("#mindmap").position();
      $("#mindmap").css("left", oldPosition.left - directionX).css("top", oldPosition.top - directionY);
      previousX = e.targetTouches[0].pageX;
      previousY = e.targetTouches[0].pageY;
    }
  });

  $(document).mousedown(function(e) {
    var target = $(e.target);
    if (!mousedisabled && (target[0].id == "mindmap") || target[0].id == "view" || target.hasClass("node_root") || target.hasClass("children_item")) {
      e.preventDefault();
      previousX = e.clientX;
      previousY = e.clientY;
      clicking = true;
    } else {
      clicking = false;
    }
  });

  $(document).mouseup(function(e) {
    clicking = false;
  });

  $(document).mousemove(function(e) {
    if (clicking) {
      e.preventDefault();
      var directionX = previousX - e.clientX;
      var directionY = previousY - e.clientY;
      var oldPosition = $("#mindmap").position();
      $("#mindmap").css("left", oldPosition.left - directionX).css("top", oldPosition.top - directionY);
      previousX = e.clientX;
      previousY = e.clientY;
    }
  });
}

/*
 * Binds the clickhandlers to the reset button that resets
 * the whole mindmap to its initial state, to the center
 * button that moves the user back to the center of the view and
 * to the privacy-link that opens the popup.
 */
function bindButtonClickHandlers() {
  $("#reset_button").click(function() {
    var initialNodes = $(".children_leftbranch, .children_rightbranch").children(".children_item");

    // Remove all subtrees.
    $.each(initialNodes, function(index, node) {
      $(node).find(".children.nested").first().animate({opacity: 0}, {duration: 500, queue: false, complete: function() {
        $(this).html("").css("opacity", 1);
      }});
      $(node).find(".node_expand.active").removeClass("active");
    });

    // Uncheck all checkboxes and close the checklists.
    $.each($("#mindmap").find(".node.checklist"), function (index, node) {
      $(this).removeClass("active");
      if ($(this).data("original-size") > 0) {
        $(this).height($(this).data("original-size")).data("original-size", 0);
      }
      $(this).find(".node_checklist_progressbar").find(".bar").width(0);
      $(this).find("input:checkbox").prop("checked", false);
    });

    // Replace the text bubble if needed.
    if ($(this).data("message") && $(this).data("message").length > 0) {
      replaceBubble($(this).data("message"));
    }

    $("#mindmap").animate({
      left: 0,
      top: 0
    }, 1000);
  });
  $("#center_button").click(function() {
    centerView();
  });
  $("#privacy_button").click(function() {
    mousedisabled = true;
    $("#overlay").fadeIn(200);
    $("#privacy_policy").fadeIn(200).scrollTop(0);
  });
  $("#accept_button, #overlay").click(function() {
    mousedisabled = false;
    $("#privacy_policy").fadeOut(200);
    $("#overlay").fadeOut(200);
  });
}

/*
 * Initializes the mindmap based on the selected study and year.
 */
function loadMindmap(study, year) {
  var studies = Object.keys(jsondata.content);

  if (editormode) {
    // Newly created study, needs to be created first.
    if (isNaN(study)) {
      jsondata.content[study] = {};
      studies.push(study);
      study = studies.length - 1;
    }
  }

  var studyObject = jsondata.content[studies[study]];
  var years = Object.keys(studyObject);

  if (editormode) {
    // Newly created year, also needs to be created first.
    if (isNaN(year)) {
      jsondata.content[studies[study]][year] = {
        textbubble: {
          welcomeMessage: "Welkom!",
          resetMessage: "Reset!"
        }
      };
      years.push(year);
      year = years.length - 1;
    }
  }

  var data = studyObject[years[year]];

  $("#reset_button").data("message", data["textbubble"]["resetMessage"]);

  $(".node_root").children().removeClass("startscreen");

  replaceBubble(data["textbubble"]["welcomeMessage"]);

  // Create the new nodes.
  var leftBranch = $("#leftbranch");
  var rightBranch = $("#rightbranch");

  $(leftBranch, rightBranch).css("display", "none");

  $.each(data.nodes, function(index, nodeData) {
    var node = nodeBuilder(nodeData);
    if (index % 2 == 0) {
      leftBranch.append(node);
    } else {
      rightBranch.append(node);
    }
  });

  nodewidth = $(".node").first().outerWidth() || 250;
  nodeheight = $(".node").first().outerHeight() || 50;

  $(leftBranch, rightBranch).fadeIn({duration: 500, queue: false});
  $("#reset_button").fadeIn({duration: 500, queue: false});
  $("#center_button").fadeIn({duration: 500, queue: false});

  setTimeout(function() {
    $("#hint").fadeIn(350).delay(7000).fadeOut(350);
  }, 2500);

  // Store some more data used for the editor.
  if (editormode) {
    $(".node_root").data("globalproperties", {
      textbubble: data["textbubble"],
      year: years[year],
      study: studies[study]
    })
  }
}

/*
 * Replaces the current textbubble with a new textubble
 * containing the given HTML.
 */
function replaceBubble(newHTML) {
  var oldBubbles = $(".textbubble");
  var newBubble = document.createElement("div");
  var content = document.createElement("span");
  $(content).html(newHTML);
  $(newBubble).addClass("textbubble").css("display", "none").append(content);
  $(".node_root").prepend(newBubble);
  oldBubbles.fadeOut(500, function() {
    $(this).remove();
  });
  $(newBubble).delay(500).fadeIn(500);
}

/*
 * Helper function to use the right builder function
 * to create the requested node.
 */
function nodeBuilder(node) {
  switch (node.type) {
    case "checklist":
      var createdNode = nodeChecklistBuilder(node);
      break;
    case "text":
      var createdNode = nodeTextBuilder(node);
      break;
    case "youtube":
      var createdNode = nodeYoutubeBuilder(node);
      break;
    default:
      console.error("Unsupported node type!");
      return
  }

  $(createdNode).children(".node").data("properties", node);

  if (editormode) {
    $(createdNode).children(".node").addClass("editor_editable");
  }
  return createdNode;
}

/*
 * Builds the base-element all nodes are based on.
 */
var counter = 0;

function nodeBaseBuilder(nodeData) {
  var nodeID = "node-" + counter++;

  // Base HTML structure.
  var children_item = document.createElement("li");
  var node = document.createElement("div");
  var node__content = document.createElement("div");
  var node__text = document.createElement("div");
  var node_name = document.createElement("span");
  var node__active_content = document.createElement("div");
  var children = document.createElement("ol");
  $(children_item).addClass("children_item").attr("id", nodeID);
  $(node).addClass("node").css("background-color", nodeData.color);
  $(node__content).addClass("node__content");
  $(node_name).addClass("node_name").html(nodeData.name);
  $(node__text).addClass("node__text").append(node_name);
  $(node__active_content).addClass("node__active_content");
  $(children).addClass("children nested");

  // Add the expand-arrow if this node has any children.
  if (nodeData.children && nodeData.children.length > 0) {
    var node_expand = document.createElement("div");
    var chevron = document.createElement("i");
    var pipe = document.createElement("div");
    $(node_expand).addClass("node_expand").css("background-color", nodeData.color);
    $(chevron).addClass("fa fa-chevron-dynamic");
    $(pipe).addClass("pipe");
    $(node_expand).append(chevron).append(pipe);
    $(node).prepend(node_expand);
    bindBaseNodeExpansionHandler(node);
  }

  // Style the lines to the node.
  if (navigator.userAgent.toLowerCase().indexOf('firefox') > -1) {
    // Firefox works slightly different.
    document.styleSheets[0].insertRule("#" + nodeID + ".children_item, #" + nodeID + ".children_item:before { border-color: " + nodeData.color + "}");
  } else {
    document.styleSheets[0].addRule("#" + nodeID + ".children_item, #" + nodeID + ".children_item:before", "border-color: " + nodeData.color);
  }

  // Close/open arrow.
  var node__arrow = document.createElement("div");
  var chevron = document.createElement("i");
  $(chevron).addClass("fa fa-chevron-right");
  $(node__arrow).addClass("node__arrow").append(chevron);
  $(node__text).append(node__arrow);

  // Add the click handler.
  bindBaseNodeClickHandler(node__content);

  $(node__text).append(node__active_content);
  $(node__content).append(node__text);
  $(node).append(node__content);
  return $(children_item).append(node).append(children);
}

/*
 * Binds the basic click handler for each node that allows the node
 * to expand and contract.
 */
function bindBaseNodeClickHandler(node) {
  if (editormode) {
    $(node).click(function(e) {
      loadObjectClickHandler(e, $(this).parent());
    });
  }
  $(node).click(function(e) {
    if (e.target.className == "" || $(e.target).hasClass("container") || $(e.target).hasClass("checkmark")) {
      return;
    }
    $(this).parent().toggleClass("active");
    if ($(this).parent().data("original-size") > 0) {
      $(this).parent().height($(this).parent().data("original-size"));
      $(this).parent().data("original-size", 0);

      // If not blank, display the close-click message.
      if ($(node).parent().data("properties") && $(node).parent().data("properties")["closeMessage"] != "") {
        replaceBubble($(node).parent().data("properties")["closeMessage"]);
      }
    } else {
      var originalHeight = 0;
      $(this).parent().height(function (index, height) {
        originalHeight = height;
        return height + $(this).find(".node__active_content").outerHeight();
      });
      $(this).parent().data("original-size", originalHeight);
      // If not blank, display the open-click message.
      if ($(node).parent().data("properties") && $(node).parent().data("properties")["openMessage"] != "") {
        replaceBubble($(node).parent().data("properties")["openMessage"]);
      }
    }
  });
}

/*
 * Binds the handler to the side-arrow that enables
 * opening and closing of subtrees.
 */
function bindBaseNodeExpansionHandler(node) {
  $(node).find(".node_expand").click(function(e) {
    $(this).toggleClass("active");

    var container = $(this).parent().parent().find(".children.nested").first();
    if ($(this).hasClass("active")) {
      $.each($(node).data("properties").children, function(index, child) {
        var childNode = nodeBuilder(child);
        $(childNode).css("width", 0);
        $(childNode).find(".node").css("height", 0);
        $(container).append(childNode);
      });
      var moveX = ($(document).width() / 2 - nodewidth / 2) - $(container).offset().left;
      $(container).find(".node").animate({height: nodeheight}, {duration: 450, queue: false});
      $(container).find("li.children_item").animate({width: nodewidth}, {duration: 450, queue: false});
      $("#mindmap").animate({left: $("#mindmap").position().left + moveX}, {duration: 450, queue: false});
    } else {
      var moveX = ($(document).width() / 2 - nodewidth / 2) - $($(container).parent()[0]).offset().left;
      $(container).find(".node").animate({height: 0}, {duration: 450, queue: false, complete: function() {
        $(container).find("li.children_item").animate({width: 0}, {duration: 250, queue: false, complete: function() {
          $(this).remove();
          if ($("#mindmap").find(".node_expand.active").length > 0) {
            $("#mindmap").animate({left: $("#mindmap").position().left + moveX}, {duration: 450, queue: false});
          } else {
            centerView();
          }
        }});
      }});
    }
  })
}

/*
 * Builds the HTML for a checklist-node.
 */
function nodeChecklistBuilder(nodeData) {
  var checklistNode = nodeBaseBuilder(nodeData);
  checklistNode.find(".node").addClass("checklist");

  // Create the progressbar.
  var node_checklist_progressbar = document.createElement("div");
  var bar = document.createElement("div");
  $(node_checklist_progressbar).addClass("node_checklist_progressbar");
  $(bar).addClass("bar");
  $(node_checklist_progressbar).append(bar);
  checklistNode.find(".node__text").prepend(node_checklist_progressbar);

  // Add all items to the checklist.
  var checklist = document.createElement("ul");
  var checklistID = $(checklistNode).attr("id");

  if (navigator.userAgent.toLowerCase().indexOf('firefox') > -1) {
    document.styleSheets[0].insertRule("#" + checklistID + " .checkmark:after { border:solid " + nodeData.color + "!important;border-width: 0 3px 3px 0!important;}");
  } else {
    document.styleSheets[0].addRule("#" + checklistID + " .checkmark:after","border:solid " + nodeData.color + "!important;border-width: 0 3px 3px 0!important;");
  }

  $.each(nodeData.data.theorems, function(index, content) {
    var item = document.createElement("li");
    var label = document.createElement("label");
    var checkbox = document.createElement("input");
    var checkmark = document.createElement("div");

    $(label).addClass("container").html(content);
    $(checkbox).attr("type", "checkbox");
    $(checkmark).addClass("checkmark").addClass(checklistID);

    $(item).append($(label).append(checkbox).append(checkmark));
    $(checklist).append(item);
  });
  checklistNode.find(".node__active_content").append(checklist);
  $(checklistNode).data("feedback", nodeData.data.feedback);
  bindChecklistHandlers(checklistNode);

  return checklistNode;
}

/*
 * Builds the HTML for a text-based node.
 */
function nodeTextBuilder(nodeData) {
  var textNode = nodeBaseBuilder(nodeData);
  $(textNode).find(".node").addClass("text");
  $(textNode).find(".node__active_content").html(nodeData.data[0]);

  return textNode;
}

/*
 * Builds the HTML for a youtube-based node.
 */
function nodeYoutubeBuilder(nodeData) {
  var youtubeNode = nodeBaseBuilder(nodeData);
  $(youtubeNode).find(".node").addClass("youtube");

  // If text is given, add the text to the node.
  if (nodeData.data[1] && nodeData.data[1].length > 0) {
    var text = document.createElement("div");
    $(text).html(nodeData.data[1]);
    $(text).addClass("text");
    $(youtubeNode).find(".node__active_content").append(text);
  }

  var youtube = document.createElement("iframe");
  $(youtube).attr("frameborder", "0");
  $(youtube).attr("allowfullscreen", "");
  $(youtube).attr("src", "https://www.youtube.com/embed/" + nodeData.data[0]);
  $(youtubeNode).find(".node__active_content").append(youtube);

  return youtubeNode;
}

/*
 * Binds the handlers to the checkboxes that will update
 * the progressbar.
 */
function bindChecklistHandlers(checklist) {
  $(checklist).find(".node__active_content :checkbox").change(function() {
    // Opens the subtree if not already opened.
    $(this).closest(".node").find(".node_expand").not(".active").click();

    var nChecked = $(this).closest("ul").children("li")
                                        .children(".container")
                                        .children("input[type='checkbox']:checked")
                                        .length;
    var nTotal = $(this).closest("ul").children("li").length;
    var percentage = nChecked / nTotal * 100;
    $(this).closest(".node").find(".bar").width(percentage + "%");

    var message = "";
    $.each($(checklist).data("feedback"), function (trigger, feedback) {
      if (trigger <= parseInt(percentage)) {
        message = feedback;
      } else {
        return;
      }
    });
    if (message.length > 0 && $(".textbubble").find("span").text() != message) {
      replaceBubble(message);
    }
  });
}

/*
 * Animates scrolling the mindmap to the center of the view.
 */
function centerView() {
  $("#mindmap").animate({
    left:  $(document).width() / 2 - $(".node_root").first().width() - $(".node_root").first().position().left,
    top: 0
  }, 1000);
}
