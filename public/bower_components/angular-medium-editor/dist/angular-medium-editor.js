/*global MediumEditor */
'use strict';

angular.module('angular-medium-editor', [])

.directive('mediumEditor', function() {

  function toInnerText(value) {
    var tempEl = document.createElement('div'),
      text;
    tempEl.innerHTML = value;
    text = tempEl.textContent || '';
    return text.trim();
  }

  function isImgTag(value){
    return /[<>]img/.test(value)
  }

  return {
    require: 'ngModel',
    restrict: 'AE',
    scope: { bindOptions: '&' },
    link: function(scope, iElement, iAttrs, ngModel) {

      angular.element(iElement).addClass('angular-medium-editor');

      // Global MediumEditor
      ngModel.editor = new MediumEditor(iElement, scope.bindOptions());

      ngModel.$render = function() {
        var elem = iElement
        if(iElement[0].tagName.toLowerCase() === "textarea")
          elem = iElement.parent().find(".medium-editor-element")
        elem.html(ngModel.$viewValue || "");
        var placeholder = ngModel.editor.getExtensionByName('placeholder');
        if(placeholder) {
          placeholder.updatePlaceholder(elem[0]);
        }
      };

      ngModel.$isEmpty = function(value) {
        if(/[<>]/.test(value)) {
          return toInnerText(value).length === 0 && !isImgTag(value);
        } else if(value) {
          return value.length === 0;
        } else {
          return true;
        }
      };

      ngModel.editor.subscribe('editableInput', function(event, editable) {
        scope.$apply(function() {
          var el = $(editable)
          if(el.text().trim() === "" && el.find("img").length == 0 ){
            el.html("")
          }
          el.find("p").addClass("medium-editor-p")
          ngModel.$setViewValue(el.html().trim());
        })
      });

      scope.$on('$destroy', function() {
        ngModel.editor.destroy();
      });
    }
  };

});
