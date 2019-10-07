# Lists all node-properties that can be edited.
EDITABLE_PROPERTIES = [
  "name",
  "color",
  "messages_open",
  "messages_close",
  "weight",
  "data_theorems",
  "data_feedback",
  "data_text",
  "data_url",
  "type"
]

# Maps all internal property-names
# to normal names.
NORMALIZED_NAMES = {
  "name": "Naam",
  "color": "Kleur",
  "messages_open": "Openingstekst",
  "messages_close": "Sluitingstekst",
  "weight": "Positie"
  "data_theorems": "Stellingen",
  "data_feedback": "Feedback",
  "data_text": "Tekst",
  "data_url": "Video link",
  "type": "Node Type"
}

# Mapping of editable properties from their
# internal name to their input-type.
PROPERTY_TYPES = {
  "name": "text",
  "color": "color",
  "messages_open": "multilinetext",
  "messages_close": "multilinetext",
  "weight": "position",
  "data_theorems": "multitext",
  "data_feedback": "feedback",
  "data_text": "multilinetext",
  "data_url": "videourl",
  "type": "nodetype"
}