//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//History: Mon, Apr 23, 2012  6:02:46 PM
// Author: tomyeh

/** Renders the given data for the given [RadioGroup].
 *
 * The simplest implementation is to return a string representing the given data.
 * If you'd like more complicated presentation, you can return a HTML fragment
 * (by use of [HTMLFragment.html]).
 *
 * By default, [RadioGroup] will wrap the returned fragment with HTML radio or checkbox.
 * If you prefer to do it in the renderer, remember to specify the complete parameter
 * when calling [HTMLFragment.html].
 * Notice that the input's id attribute must be `"${group.uuid}-$index"`.
 * In additions, you have to render the selected and disabled attributes correctly.
 */
typedef HTMLFragment RadioGroupRenderer(
  RadioGroup group, var data, bool multiple, bool selected, bool disabled, int index);

/**
 * A radio group.
 *
 * ##Events
 *
 * + select: an instance of [SelectEvent] indicates the selected item has been changed.
 */
class RadioGroup<E> extends View {
  ListModel<E> _model;
  DataEventListener _dataListener;
  RadioGroupRenderer _renderer;
  bool _modelSelUpdating = false; //whether it's updating model's selection

  RadioGroup([ListModel<E> model, RadioGroupRenderer renderer]) {
    _renderer = renderer;
    this.model = model;
  }

  //@Override
  String get className() => "RadioGroup"; //TODO: replace with reflection if Dart supports it

  //Model//
  /** Returns the model.
   */
  ListModel<E> get model() => _model;
  /** Sets the model.
   */
  void set model(ListModel<E> model) {
    if (model !== null) {
      if (model is! Selection)
        throw new UIException("Selection required, $model");

      if (_model !== model) { //Note: it is not !=
        if (_model !== null)
          _model.on.all.remove(_dataListener);

        _model = model;
        _model.on.all.add(_initDataListener());
      }
      modelRenderer.queue(this); //queue for later operation (=> renderModel_)
    } else if (_model !== null) {
      _model.on.all.remove(_dataListener);
      _model = null;
      children.clear();
    }
  }
  DataEventListener _initDataListener() {
    if (_dataListener === null) {
      _dataListener = (event) {
        if (event.type == 'select') {
          if (!_modelSelUpdating) {
            final String idPrefix = "$uuid-";
            final Selection<E> selmodel = _cast(_model);
            final bool multiple = selmodel.multiple;
            int i = 0, len = _model.length;
            for (final InputElement inp in node.queryAll("input")) {
              if (i >= len)
                return; //done
              if (inp.id.startsWith(idPrefix)) {
                final bool seled = inp.checked = selmodel.isSelected(_model[i++]);
                if (!multiple && seled)
                  return; //done
              }
            }
          }
          return;
        }

        modelRenderer.queue(this);
      };
    }
    return _dataListener;
  }
  /** Returns the renderer used to render the given model ([model]), or null
   * if the default implementation is preferred.
   *
   * The default implementation coerces the given data to a string, and then use
   * it as the label of the radio button or check box (depending on if it allows
   * mulitple selection).
   */
  RadioGroupRenderer get renderer() => _renderer;
  /** Sets the renderer used to render the given model ([model]).
   * If null, the default implementation is used.
   */
  void set renderer(RadioGroupRenderer renderer) {
    if (_renderer !== renderer) {
      _renderer = renderer;
      if (_model !== null)
        modelRenderer.queue(this);
    }
  }
  /** callback by [modelRenderer] to render the model into views.
   */
  void renderModel_() {
    final StringBuffer out = new StringBuffer();
    final List<AfterMount> callbacks = new List();
    _renderInner(out,  callbacks);

    node.innerHTML = out.toString();
    _initRadios();

    for (final AfterMount callback in callbacks)
      callback(this);

    sendEvent(new ViewEvent("render"));
  }

  //@override
  void domInner_(StringBuffer out) {
    _renderInner(out, null);
  }  

  void _renderInner(StringBuffer out, List<AfterMount> callbacks) {
    if (_model === null)
      return; //nothing to do

    final RadioGroupRenderer renderer =
      _renderer !== null ? _renderer: _defRenderer();
    final model = _cast(_model);
    final bool multiple = model.multiple;
    final String type = multiple ? "checkbox": "radio";
    for (int i = 0, len = _model.length; i < len; ++i) {
      final obj = _model[i];
      final bool selected = model.isSelected(obj);
      final bool disabled = model is Disables && model.isDisabled(obj);
      final HTMLFragment hf = renderer(this, obj, multiple, selected, disabled, i);

      final AfterMount callback = hf.mount;
      if (callback !== null) {
        if (callbacks !== null)
          callbacks.add(callback);
        else
          afterMount_(callback); //called by domInner_
      }

      final bool complete = hf.isComplete();
      if (!complete) {
        final String inpId = "$uuid-$i";;
        out.add('<input type="').add(type).add('" name="').add(uuid)
          .add('" id="').add(inpId).add('"');
        if (selected)
          out.add(' checked="checked"');
        if (disabled)
          out.add(' disabled="disabled"');
        out.add('/><label for="').add(inpId).add('">');
      }

      out.add(hf.html);

      if (!complete)
        out.add('</label> ');
    }
  }
  static _cast(var v) => v; //TODO: replace with 'as' when Dart supports it
  static RadioGroupRenderer _defRenderer() {
    if (_$defRenderer === null)
      _$defRenderer = (RadioGroup group, var data, bool multiple, bool selected, bool disabled, int index)
      => new HTMLFragment(data);
    return _$defRenderer;
  }
  static RadioGroupRenderer _$defRenderer;
  void _onCheck(int index, bool checked) {
    final Selection<E> selmodel = _cast(_model);
    _modelSelUpdating = true;
    try {
      if (checked)
        selmodel.addToSelection(_model[index]);
      else
        selmodel.removeFromSelection(_model[index]);
    } finally {
      _modelSelUpdating = false;
    }

    if (selmodel.multiple || !checked) {
      if (selmodel.isSelectionEmpty()) {
        index = -1;
      } else if (!checked || selmodel.selection.length > 1) {
        index = 0;
        for (int len = _model.length; index < len; ++index)
          if (selmodel.isSelected(_model[index]))
            break; //found
      }
    }
    sendEvent(new SelectEvent(selmodel.selection, index));
  }
  void _initRadios() {
    EventListener onClick = (Event event) {
      final InputElement n = event.srcElement;
      final String id = n.id;
      final int i = id.lastIndexOf('-');
      _onCheck(Math.parseInt(id.substring(i + 1)), n.checked);
    };

    final String idPrefix = "$uuid-";
    for (final InputElement inp in node.queryAll("input"))
      if (inp.id.startsWith(idPrefix))
        inp.on.change.add(onClick);
  }

  //@Override
  /** Returns false to indicate this view doesn't allow any child views.
   */
  bool isViewGroup() => false;
}
