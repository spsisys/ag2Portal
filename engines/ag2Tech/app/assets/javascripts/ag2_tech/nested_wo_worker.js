/*
 * Methods to add 'fields' to the Worker order Workers table 
 * Very important!!:
 *  1. remove_fields() & add_fields() are in main nested.js!!
 *  1. Modal window must be named (ie, 'new-worker-fields')
 *  2. Items table must be named (ie. 'workers-table')
 *  3. Each row in Items table must have 'class="fields"'
 *  4. Each field in modal window, to add to the table, must have 'class="field"'
 * >> This global methods are in main nested.js!!
 */

var wo_workerFieldsUI = {
    init: function(sel2NoMatches) {
        var validationSettings = {
            errorMessagePosition : 'element'
        };

        $('#addWorkerButton').on('click', function(e) {
            var isValid = $(wo_w_cfg.formId).validate(false, validationSettings);
            if(!isValid) {
                e.stopPropagation();
                return false;
            }
            wo_w_formHandler.appendFields(sel2NoMatches);
            wo_w_formHandler.hideForm();
        });
    }
};

var wo_w_cfg = {
    formId: '#new-worker-fields',
    tableId: '#workers-table',
    inputFieldClassSelector: '.field',
    getTBodySelector: function() {
        return this.tableId + ' tbody';
    }
};

var wo_w_formHandler = {
    // Public method for adding a new row to the table.
    appendFields: function (sel2NoMatches) {
        // Get a handle on all the input fields in the form and detach them from
		    // the DOM (we'll attach them later).
        var inputFields = $(wo_w_cfg.formId + ' ' + wo_w_cfg.inputFieldClassSelector);
        inputFields.detach();

        // Build the row and add it to the end of the table.
        wo_w_rowBuilder.addRow(wo_w_cfg.getTBodySelector(), inputFields);

        // Apply select2 to added row selects
        $('select.isel2').select2('destroy');
        $('select.isel2').select2({
          formatNoMatches: function(m) { return sel2NoMatches; },
          dropdownCssClass: 'shrinked',
          dropdownAutoWidth: true,
          containerCssClass: 'sub-select2-field'
        });
    },

    // Public method for hiding the data entry fields.
    hideForm: function() {
        // Update and display totals
        $(wo_w_cfg.tableId).trigger('totals');
        // Hide modal
        $(wo_w_cfg.formId).modal('hide');
    }
};

var wo_w_rowBuilder = function() {
    // Private property that define the default <TR> element text.
    var row = $('<tr>', { class: 'fields' });

    // Public property that describes the "Remove" link.
    var link = $('<a>', {
        href: '#',
        onclick: 'remove_fields(this); $("#workers-table").trigger("totals"); return false;'
    }).append($('<i>', { class: 'icon-trash' }));

    // A private method for building a <TR> w/the required data.
    var buildRow = function(fields) {
        var newRow = row.clone();
        var newLink = link.clone();

        // fields
        $(fields).map(function() {
            var css = '';
            // Add only if not select2 link
            if (this.id.indexOf("s2") == -1) {
              // Apply CSS
              css = this.id;
              if ($(this).hasClass('fsel2')) css = css + ' select isel2';
              if ($(this).hasClass('number-text-field')) css = css + ' sub-number-text-field';
              if ($(this).hasClass('sub-disabled-field')) css = css + ' sub-disabled-field';
              if (css === this.id) css = css + ' sub-alfanumeric-text-field';
              if (css.indexOf("isel2") == -1) css = css + ' sub-bordered-input';
              css = css + ' string';
              $(this).removeAttr('class');
              $(this).addClass(css);
              // Add new column to row
              var td = $('<td/>').append($(this));
              // ...hiding this if applicable
              /*
              if (this.id === 'fnt-tax-type') {
                td = $('<td style="display:none;"/>').append($(this));
              }
              */
              // If destroy field, add delete link also
              if (this.id.indexOf("_destroy") != -1) {
                var td = $('<td/>').append($(this), newLink);
              }
              td.appendTo(newRow);
            }
        });

        return newRow;
    };

    // A public method for building a row and attaching it to the end of a
	// <TBODY> element.
    var attachRow = function(tableBody, fields) {
        var row = buildRow(fields);
        $(row).appendTo($(tableBody));
    };

    // Only expose public methods/properties.
    return {
        addRow: attachRow,
        link: link
    };
}();
