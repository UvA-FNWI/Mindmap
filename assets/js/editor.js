// SET THIS TO THE PATH WHERE DATA CAN BE SAVED TO.
var SAVE_DATA_PATH = "/mindmap/save.php";

/*
 * Enable editor mode.
 * This will add more data to each node
 * at its creation to allow the editor to work.
 */
editormode = true;

/*
 * Contains the interal property names of
 * all editable node-properties.
 */
var EDITABLE_PROPERTIES = ["name", "color", "openMessage", "closeMessage", "type", "data"];

/*
 * Contains the mapping of each standard
 * internal node property to the type of input
 * needed.
 */
var INPUT_TYPES = {
  name: "text",
  color: "color",
  openMessage: "textarea",
  closeMessage: "textarea",
  type: "dropdown",
  data: "varying",
  welcometext: "text",
  resettext: "text",
  study: "text",
  year: "text"
}

/*
 * Contains the internal names of all available
 * node types.
 */
var SUPPORTED_TYPES = ["checklist", "text", "youtube"];

/*
 * Contains the translations from internal
 * property names to normalized names for displaying.
 */
var NORMALIZED_PROPERTY_NAMES = {
  name: "Naam",
  color: "Kleur",
  openMessage: "Openingstekst",
  closeMessage: "Sluitingstekst",
  type: "Type",
  welcometext: "Welkomsttekst",
  resettext: "Resettekst",
  study: "Studie",
  year: "Studiejaar"
}

// Initialize the editor.
$(document).ready(function() {
  mindmapEditor.initialize();
});

/*
 * Contains helper methods for generating the
 * editor form to keep the code DRY and readable.
 */
var mindmapFormHelper = {

  // Clears the form by removing everything.
  clear: function() {
    $("#editor_form").html("");
    return this;
  },

  // Removes the hint from the form.
  removeHint: function() {
    $("#editor_form_hint").remove();
    return this;
  },

  /*
   * Creates and appends a table row to be
   * used in the editor form.
   */
  createRow: function(name, inputs) {
    var row = document.createElement("tr");
    var nameField = document.createElement("td");
    var inputField = document.createElement("td");

    nameField.innerHTML = name;
    if (Array.isArray(inputs)) {
      $.each(inputs, function(index, input) {
        inputField.appendChild(input);
      });
    } else {
      inputField.appendChild(inputs);
    }

    row.appendChild(nameField);
    if (inputField) {
      row.appendChild(inputField);
    }

    $("#editor_form").append(row);
    return this;
  },

  /*
   * Returns all values for the editor form
   * elements with the given identifier.
   */
  getValues: function(identifier) {
    return $("#editor_form").find(identifier).map(function() {
      return this.value;
    }).get();
  },

  /*
   * Creates and returns an input field with preset
   * data type and value.
   */
  createInputField: function(key, value) {
    var type = INPUT_TYPES[key];
    if (type == "text" || type == "color") {
      var inputField = document.createElement("input");
      inputField.type = type;
      inputField.value = value || "";
    } else if (type == "dropdown"){
      if (key == "type") {
        var inputField = document.createElement("select");
        $.each(SUPPORTED_TYPES, function(index, value) {
          $('<option />', {value: value, text: value}).appendTo($(inputField));
        });
      }
    } else {
      var inputField = document.createElement(type);
      inputField.value = value || "";
    }

    // Bind handlers to launch the WYSIWYG HTML editor for text inputs.
    if (type == "text" || type == "textarea") {
      inputField.onclick = function(e) {
        mindmapFormHelper.launchHTMLEditor(e, this);
      }
    }

    return inputField;
  },

  /*
   * Launches the WYSIWYG HTML editor when an input with type text
   * or a textarea has been alt-clicked.
   */
  launchHTMLEditor: function(e, inputTarget) {
    if (e.altKey) {
      e.stopImmediatePropagation();
      $("#overlay").fadeIn(200);

      // Create the WYSIWYG HTML editor.
      var output = inputTarget.value;

      var container = document.createElement("div");
      container.id = "editor_html_editor";

      var editor = document.createElement("div");
      editor.id = "editor_html_editor_input";
      $(container).append(editor);

      var saveButton = document.createElement("button");
      saveButton.className = "html_editor_button save";
      saveButton.innerHTML = "Content opslaan&nbsp;&nbsp;<i class='fas fa-save'></i>";
      saveButton.onclick = function(e) {
        // Hacky way to make all links safe and open in a new tab.
        var parsedOutput = $('<div/>').html(output);
        $(parsedOutput).find("a").attr("target", "_blank").attr("rel", "noopener noreferrer");
        $(inputTarget).val($(parsedOutput).html()).trigger("change");
        $("#editor_html_editor").fadeOut(200).remove();
        $("#overlay").fadeOut(200);
      }
      $(container).append(saveButton);

      $("body").append(container);

      pell.init({
        element: document.getElementById('editor_html_editor_input'),
        onChange: html => output = html,
        defaultParagraphSeparator: 'div',
        styleWithCSS: false,
        actions: [
          'bold',
          'underline',
          'italic',
          'strikethrough',
          'link',
          'image',
          'line',
          'ulist'
        ],
        classes: {
          actionbar: 'pell-actionbar',
          button: 'pell-button',
          content: 'pell-content',
          selected: 'pell-button-selected'
        }
      })
    }

    $(".pell-content").html($(inputTarget).val());
  }
}

/*
 * Initializes the editor and contains all methods
 * needed to work with the editor.
 */
var mindmapEditor = {

  /*
   * Creates the base interface for the admin sidemenu
   * and adds the click handler to the already
   * existing root node.
   */
  initialize: function() {
    // Creates the sidemenu.
    var adminSidePanel = document.createElement("div");
    adminSidePanel.id = "editor_side_panel";

    // Create the title label.
    var mainLabel = document.createElement("label");
    mainLabel.id = "editor_main_label";
    mainLabel.innerHTML = "Mindmap Editor";
    adminSidePanel.appendChild(mainLabel);

    // Create the table used as the form.
    var editorForm = document.createElement("table");
    editorForm.id = "editor_form";
    adminSidePanel.appendChild(editorForm);

    // Create the hint about usage.
    var hintLabel = document.createElement("div");
    hintLabel.id = "editor_form_hint";
    hintLabel.innerHTML = "Gebruik <b>alt + muisklik</b> om een element te bewerken."
    adminSidePanel.appendChild(hintLabel);

    // Add the save button.
    var saveButton = document.createElement("button");
    saveButton.className = "editor_button save";
    saveButton.innerHTML = "Mindmap opslaan&nbsp;&nbsp;<i class='fas fa-save'></i>";
    saveButton.onclick = function(e) {
      mindmapEditor.saveMindmap();
    }
    adminSidePanel.appendChild(saveButton);

    // Append the sidemenu to the body.
    $("body").append(adminSidePanel);

    // Add the click handler to the root node.
    $(".node_root").addClass("editor_editable").click(function(e) {
      loadObjectClickHandler(e, $(this));
    });
  },

  /*
   * Loads an object into the editor side-menu
   * so that its editable properties can be edited.
   */
  loadObject: function(object) {
    $(".admin_selected").removeClass("admin_selected");
    $(object).addClass("admin_selected");

    $("#editor_form").data("object", object);

    mindmapFormHelper.clear().removeHint();

    var properties = $(object).data("properties");
    if (properties) {
      $.each(properties, function (key, value) {
        if ($.inArray(key, EDITABLE_PROPERTIES) >= 0) {
          mindmapEditor.createEditorEntry(object, key, value);
        }
      })
    } else if (object.hasClass("node_root")) {
      var data = object.data("globalproperties");
      mindmapEditor.createEditorEntry(object, "study", data.study);
      mindmapEditor.createEditorEntry(object, "year", data.year);
      mindmapEditor.createEditorEntry(object, "welcometext", data.textbubble.welcomeMessage);
      mindmapEditor.createEditorEntry(object, "resettext", data.textbubble.resetMessage);
    }

    /*
     * Buttons to create a new child node or to remove this node.
     */
    var buttonRow = document.createElement("tr");
    var buttonColumn = document.createElement("td");

    var addButton = document.createElement("button");
    addButton.className = "editor_button add";
    addButton.innerHTML = "Voeg node toe&nbsp;&nbsp;<i class='fas fa-plus-square'></i>";
    $(addButton).click(function() {
      mindmapEditor.addNode(object);
    });
    $(buttonColumn).append(addButton);

    if (!object.hasClass("node_root")) {
      var deleteButton = document.createElement("button");
      deleteButton.className = "editor_button delete";
      deleteButton.innerHTML = "Verwijder geselecteerde node&nbsp;&nbsp;<i class='fas fa-trash-alt'></i>";
      $(deleteButton).click(function() {
        mindmapEditor.removeNode(object);
      });
      $(buttonColumn).append(deleteButton);
    }

    buttonColumn.colSpan = "2";
    $(buttonColumn).css("text-align", "center");
    $(buttonRow).append(buttonColumn);
    $("#editor_form").append(buttonRow);

    this.bindEditorFormHandlers(object);
  },

  bindEditorFormHandlers: function(object) {
    var self = this;

    // Binds the change event handlers to the inputs.
    $("#editor_form").find("input, textarea, select").off("change").on("change", function() {
      var element = $("#editor_form").data("object");
      var property = $(this).data("property");
      var newValue = $(this).val();
      mindmapEditor.updateNode(element, property, newValue);
    });

    // Bind dataform-related handlers.

    // Checklist theorem removal.
    $(".remove_theorem").off("click").on("click", function() {
      $(this).parent().remove();
      var theorems = [];
      $.each($(".editor_node_theorem"), function(index, field) {
        theorems.push($(field).val());
      });
      $(object).data("properties").data.theorems = theorems;
    });

    // Checklist theorem addition.
    $(".add_theorem").off("click").on("click", function() {
      var inputBox = document.createElement("div");
      var inputField = document.createElement("input");
      var removeButton = document.createElement("i");

      inputField.type = "text";
      inputField.value = "";
      inputField.onclick = function(e) {
        mindmapFormHelper.launchHTMLEditor(e, this);
      }
      $(inputField).data("property", "data").addClass("editor_node_theorem");
      removeButton.className = "fas fa-trash-alt remove_editor_entry remove_theorem";
      $(inputBox).append(inputField, removeButton).insertBefore(".editor_theorem_add_box");
      self.bindEditorFormHandlers(object);
    });

    // Checklist trigger removal.
    $(".remove_trigger").off("click").on("click", function() {
      $(this).parent().remove();
      var feedback = {}
      var triggerValues = mindmapFormHelper.getValues(".editor_node_trigger");
      var feedbackValues = mindmapFormHelper.getValues(".editor_node_feedback");
      $.each(triggerValues, function(index, value) {
        feedback[value] = feedbackValues[index];
      });
      $(object).data("properties").data.feedback = feedback;
    });

    // Checklist trigger addition.
    $(".add_trigger").off("click").on("click", function() {
      var triggerDiv = document.createElement("div");

      var triggerInput = document.createElement("input");
      var triggerRow = document.createElement("div");
      triggerInput.type = "number";
      triggerInput.min = 0;
      triggerInput.max = 100;
      triggerInput.value = 50;
      $(triggerInput).data("property", "data").addClass("editor_node_trigger");

      triggerRow.className = "editor_node_trigger_row";
      triggerRow.style.display = "inline-block";
      $(triggerRow).append(triggerInput, "%");

      var feedbackInput = document.createElement("textarea");
      feedbackInput.value = "";
      feedbackInput.onclick = function(e) {
        mindmapFormHelper.launchHTMLEditor(e, this);
      }
      $(feedbackInput).data("property", "data").addClass("editor_node_feedback");

      var removeButton = document.createElement("i");
      removeButton.className = "fas fa-trash-alt remove_editor_entry remove_trigger";

      $(triggerDiv).append(removeButton, triggerRow, feedbackInput).insertBefore(".editor_trigger_add_box");
      self.bindEditorFormHandlers(object);
    });
  },

  /*
   * Creates an entry in the form for a specifc key value
   * pair of the given object.
   */
  createEditorEntry: function(object, key, value) {
    if (INPUT_TYPES[key] != "varying") {
      var inputField = mindmapFormHelper.createInputField(key, value);
      $(inputField).data("property", key);
      if (key == "type") {
        $(inputField).val(object.data("properties")["type"]);
      }
      mindmapFormHelper.createRow(NORMALIZED_PROPERTY_NAMES[key], inputField);
    } else {
      // Specific case for data-fields since these vary per type of node.
      var inputFields = this.createEditorDataForm(object, value);
      $("#editor_form").append(inputFields);
    }
  },

  /*
   * Updates a given property of an element to a new value.
   */
  updateNode: function(object, property, value) {
    if (property == "data") {
      // Node type-specific values.
      this.updateNodeData(object);
    } else if ($(object).hasClass("node_root")) {
      // Global properties.
      this.updateRootNode(object, property, value);
      return
    } else {
      $(object).data("properties")[property] = value;
    }
    mindmapEditor.loadObject(object);
    var newChild = nodeBuilder($(object).data("properties"));
    $(object).parent().replaceWith(newChild);
    $("#editor_form").data("object", newChild.find(".node"));
    this.bindEditorFormHandlers(newChild.find(".node"));
  },

  /*
   * Updates a give (global) property on the rootnode.
   */
  updateRootNode: function(object, property, value) {
    switch (property) {
      case "welcometext":
        $(".node_root").data("globalproperties").textbubble.welcomeMessage = value;
        break;
      case "resettext":
        $(".node_root").data("globalproperties").textbubble.resetMessage = value;
        $("#reset_button").data("message", value);
        break;
      default:
        /*
         * Add "new_" to the key since we still need the old value to remove
         * the old entry before creating a new one with different keys.
         */
        $(".node_root").data("globalproperties")["new_" + property] = value;
        break;
    }
  },

  /*
   * Completely removes a node and its children from the DOM
   * and the datastructure.
   */
  removeNode: function(object) {
    if (confirm("Weet je zeker dat je de geselecteerde node wilt verwijderen?")) {
      var parent = $(object).parent(".children_item").parent(".children.nested").parent(".children_item").children(".node").first();

      // Delete the reference to this node from the parent.
      if ($(parent).data("properties")) {
        var childToRemove = $(object).data("properties");
        var oldChildren = $(parent).data("properties").children;
        var newChildren = $.grep(oldChildren, function(child, index) {
          return (child != childToRemove);
        });
        $(parent).data("properties").children = newChildren;
      }
      // And remove it from the DOM.
      $(object).parent(".children_item").remove();
    }
  },

  /*
   * Adds a node to both the DOM and the datastructure.
   */
  addNode: function(parent) {
    var newNode = {
      name: "Nieuwe node",
      openMessage: "",
      closeMessage: "",
      color: "#6b2565",
      type: "text",
      data: ["Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."],
      children: []
    }
    var newChildNode = nodeBuilder(newNode);

    if (!$(parent).hasClass("node_root")) {
      if (!$(parent).data("properties").children) {
        $(parent).data("properties").children = [];
      }
      $(parent).data("properties").children.push(newNode);

      // Create a new expand-chevron if needed.
      if ($(parent).find(".node_expand").length == 0) {
        var node_expand = document.createElement("div");
        var chevron = document.createElement("i");
        var pipe = document.createElement("pipe");

        node_expand.style.backgroundColor = $(parent).data("properties").color;
        node_expand.className = "node_expand active";
        chevron.className = "fa fa-chevron-dynamic";
        pipe.className = "pipe";

        $(node_expand).append(chevron, pipe);
        $(parent).prepend(node_expand);
        bindBaseNodeExpansionHandler(parent);
      }

      // Add and show the new node in the view.
      if (!$(parent).find(".node_expand").hasClass("active")) {
        $(parent).find(".node_expand").click();
      } else {
        $(parent).siblings(".children.nested").append(newChildNode);
      }
    } else {
      if ($("#leftbranch").children().length > $("#rightbranch").children().length) {
        $("#rightbranch").append(newChildNode);
      } else {
        $("#leftbranch").append(newChildNode);
      }
    }
  },


  /*
   * Updates the node data to reflect the changes made in the editor.
   */
  updateNodeData: function(object) {
    switch ($(object).data("properties")["type"]) {
      case "text":
        var newText = $("#editor_form").find(".editor_node_text").first().val();
        $(object).data("properties")["data"][0] = newText;
        break;
      case "youtube":
        var youtubeURL = $("#editor_form").find(".editor_node_youtube").first().val();
        var youtubeIDRegex = /(youtube\.com\/watch\?v=|youtu\.be\/)(.*?)($|\?)/gi;
        var youtubeID = youtubeIDRegex.exec(youtubeURL)[2];
        var newText = $("#editor_form").find(".editor_node_text").first().val();
        $(object).data("properties")["data"] = [youtubeID, newText];
        break;
      case "checklist":
        var data = {};
        data.theorems = mindmapFormHelper.getValues(".editor_node_theorem");
        var triggers = mindmapFormHelper.getValues(".editor_node_trigger");
        var feedback = mindmapFormHelper.getValues(".editor_node_feedback");
        data.feedback = {};
        triggers.forEach((trigger, i) => data.feedback[trigger] = feedback[i]);
        $(object).data("properties")["data"] = data;
        break;
    }
  },

  /*
   * Creates rows for the input for the node-type
   * specific data attributes.
   */
  createEditorDataForm: function(object, data) {
    switch ($(object).data("properties")["type"]) {
      case "text":
        var inputField = document.createElement("textarea");
        inputField.value = data[0] || "";
        inputField.onclick = function(e) {
          mindmapFormHelper.launchHTMLEditor(e, this);
        }
        $(inputField).data("property", "data").addClass("editor_node_text");
        var row = mindmapFormHelper.createRow("Tekst", inputField);
        return [row];
      case "checklist":
        // Theorems.
        var theoremInputs = [];
        $.each(data.theorems, function(key, value) {
          var inputBox = document.createElement("div");
          var inputField = document.createElement("input");
          var removeButton = document.createElement("i");

          inputField.type = "text";
          inputField.onclick = function(e) {
            mindmapFormHelper.launchHTMLEditor(e, this);
          }
          inputField.value = value || "";
          $(inputField).data("property", "data").addClass("editor_node_theorem");

          removeButton.className = "fas fa-trash-alt remove_editor_entry remove_theorem";

          $(inputBox).append(inputField, removeButton);

          theoremInputs.push(inputBox);
        });

        // Add-button.
        var theoremAddBox = document.createElement("div");
        var theoremAddButton = document.createElement("i");
        theoremAddBox.className = "editor_theorem_add_box"
        theoremAddButton.className = "fas fa-plus-square add_editor_entry add_theorem"
        $(theoremAddBox).append(theoremAddButton);
        theoremInputs.push(theoremAddBox);

        var theoremRow = mindmapFormHelper.createRow("Stellingen", theoremInputs);

        // Feedback.
        var feedbackInputs = [];
        $.each(data.feedback, function(key, value) {
          var triggerDiv = document.createElement("div");

          var triggerInput = document.createElement("input");
          var triggerRow = document.createElement("div");
          triggerInput.type = "number";
          triggerInput.min = 0;
          triggerInput.max = 100;
          triggerInput.value = key || 50;
          $(triggerInput).data("property", "data").addClass("editor_node_trigger");

          triggerRow.className = "editor_node_trigger_row";
          triggerRow.style.display = "inline-block";
          $(triggerRow).append(triggerInput, "%");

          var feedbackInput = document.createElement("textarea");
          feedbackInput.value = value || "";
          feedbackInput.onclick = function(e) {
            mindmapFormHelper.launchHTMLEditor(e, this);
          }
          $(feedbackInput).data("property", "data").addClass("editor_node_feedback");

          var removeButton = document.createElement("i");
          removeButton.className = "fas fa-trash-alt remove_editor_entry remove_trigger";

          $(triggerDiv).append(removeButton, triggerRow, feedbackInput);
          feedbackInputs.push(triggerDiv);
        });

        // Add-button.
        var triggerAddBox = document.createElement("div");
        var triggerAddButton = document.createElement("i");
        triggerAddBox.className = "editor_trigger_add_box"
        triggerAddButton.className = "fas fa-plus-square add_editor_entry add_trigger"
        $(triggerAddBox).append(triggerAddButton);
        feedbackInputs.push(triggerAddBox);

        var triggerRow = mindmapFormHelper.createRow("Feedback", feedbackInputs);

        return [theoremRow, triggerRow];
      case "youtube":
        var textInputField = document.createElement("textarea");
        textInputField.value = data[1] || "";
        textInputField.onclick = function(e) {
          mindmapFormHelper.launchHTMLEditor(e, this);
        }
        $(textInputField).data("property", "data").addClass("editor_node_text");

        var textRow = mindmapFormHelper.createRow("Tekst", textInputField);

        var youtubeInputField = document.createElement("input");
        var youtubePreviewImg = document.createElement("img");
        youtubeInputField.type = "text";
        youtubeInputField.value = (data[0]) ? "https://www.youtube.com/watch?v=" + data[0] : "";
        $(youtubeInputField).data("property", "data").addClass("editor_node_youtube");
        if (data[0]) {
          youtubePreviewImg.src = "https://i.ytimg.com/vi/" + data[0] + "/hqdefault.jpg"
        }
        var youtubeRow = mindmapFormHelper.createRow("Youtube Link", [youtubeInputField, youtubePreviewImg]);

        return [textRow, youtubeRow];
        break;
    }
  },

  /*
   * Removes a specific study/year combination from the json-data.
   */
  removeEntry: function(study, year) {
    delete jsondata.content[study][year];

    // Delete the study if no year is left.
    if (Object.keys(jsondata.content[study]).length == 0) {
      delete jsondata.content[study];
    }
  },

  /*
   * Constructs the new mindmap-object for the selected course
   * that can be saved on the server.
   */
  saveMindmap: function() {

    var oldStudy = $(".node_root").data("globalproperties").study;
    var oldYear = $(".node_root").data("globalproperties").year;
    var newStudy = $(".node_root").data("globalproperties").new_study;
    var newYear = $(".node_root").data("globalproperties").new_year;

    var newMindMap = {};

    // Global settings.
    newMindMap.textbubble = {
      welcomeMessage: $(".node_root").data("globalproperties").textbubble.welcomeMessage,
      resetMessage: $(".node_root").data("globalproperties").textbubble.resetMessage
    };

    // All nodes.
    newMindMap.nodes = [];
    var rootNodes = $("#leftbranch, #rightbranch").children(".children_item").children(".node");
    $.each(rootNodes, function(index, node) {
      var nodeData = $(node).data("properties");
      newMindMap.nodes.push(nodeData);
    });

    // Deal with the possible renaming of the study.
    if (typeof newStudy != "undefined") {
      jsondata.content[newStudy] = jsondata.content[oldStudy];
      delete jsondata.content[oldStudy];
    }

    var study = newStudy || oldStudy;
    var year = newYear || oldYear;

    // Renaming or not, it's safe to just delete the year anyway.
    this.removeEntry(study, oldYear);

    // Save the new mindmap to the object.
    if (typeof jsondata.content[study] == "undefined") {
      jsondata.content[study] = {};
    }
    jsondata.content[study][year] = newMindMap;

    // And finally post the new mindmap to the server.
    $.ajax({
      type: "POST",
      url: SAVE_DATA_PATH,
      data: {data: JSON.stringify(jsondata)},
      success: function (data) {
        alert("Mindmap opgeslagen!");
      },
      error: function (data) {
        console.error("error", data);
      }
    });
  }
}

/*
 * Loads the properties of an object into the editor-sidemenu
 * when an editable-object gets alt-clicked.
 */
function loadObjectClickHandler(e, object) {
  if (e.altKey) {
    e.stopImmediatePropagation();
    mindmapEditor.loadObject(object);
  }
}

/*
 * Creates a new study option.
 */
function addNewStudy() {
  var name = prompt("Wat is de naam van de nieuwe studie?");
  if (name.length < 1) {
    alert("Voer een studienaam in!");
    addNewStudy();
    return;
  }
  if (!isNaN(name)) {
    alert("Voer een studienaam in die niet bestaat uit alleen maar cijfers!");
    addNewStudy();
    return;
  }
  $("#studySelect")[0].add(new Option(name, name));
  $("#studySelect").val(name);
}

/*
 * Creates a new year option for a study.
 */
function addNewYear() {
  var year = prompt("Wat is de naam van het nieuwe studiejaar?");
  if (year.length < 1) {
    alert("Voer een naam voor het studiejaar in!");
    addNewYear();
    return;
  }
  if (!isNaN(year)) {
    alert("Voer een studiejaar naam in die niet bestaat uit alleen maar cijfers!");
    addNewStudy();
    return;
  }
  $("#yearSelect")[0].add(new Option(year, year));
  $("#yearSelect").val(year);
  $("#loadMindmapButton").prop("disabled", false);
}
