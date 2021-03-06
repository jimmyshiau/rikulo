//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//History: Fri Jan 20 14:42:46 TST 2012
// Author: tomyeh

/** A listener for handling [ViewEvent].
 */
typedef void ViewEventListener(ViewEvent event);

/**
 * A view event.
 * The event received by [View]'s event listener must be an instance of this class.
 */
class ViewEvent {
  final Event _domEvt;
  final String _type;
  final int _stamp;
  Offset _offset;
  bool _offsetReady = false;
  bool _propStop = false;

  /** Constructor.
   *
   * + [type] is the event type, such as click.
   * + [target] is the view that this event is targeting. If not specified, it will
   * be assigned automatically when the sendEvent method is called.
   * + [pageX] and [pageY] are the mouse pointer relative to the document.
   * They are ignored if not specified.
   * + [offsetX] and [offsetY] are the mouse pointer relative to [target]'s
   * left-top corner.
   * They are ignored if [pageX] and [pageY] are specified.
   * If both [offsetX] and [pageX] are not specified, 0 is assumed.
   * If this event is constructed from a DOM event (UIEvent),
   * it is UIEvent.pageX and UIEvent.pageY.
   */
  ViewEvent(String type, [View target, int pageX, int pageY, int offsetX, int offsetY]):
  _domEvt = null, _type = type, _stamp = new Date.now().millisecondsSinceEpoch {
    if (type == null)
      throw const UIException("type required");
    this.target = currentTarget = target;

    if (pageX !== null && pageY !== null) {
      _offset = new Offset(pageX, pageY);
    } else {
      _offset = new Offset(offsetX !== null ? offsetX: 0, offsetY !== null ? offsetY: 0);
      _offsetReady = true;
    }
  }
  /** Constructs a view event from a DOM event.
   * It is rarely called unless you'd like to wrap a DOM event.
   */
  ViewEvent.dom(Event domEvent, [String type, View target]) : 
  _domEvt = domEvent, _type = type != null ? type: domEvent.type,
  _stamp = domEvent.timeStamp {
    this.target = currentTarget = target;
    _offset = new Offset(0, 0);
  }

  /** The offset relative to [target]'s coordinate.
   */
  Offset get offset() {
    if (!_offsetReady) {
      _offsetReady = true;
      try {
        if (domEvent !== null) {
          if (domEvent is! UIEvent)
            return _offset;

          final UIEvent uievt = domEvent;
          _offset.x = uievt.pageX;
          _offset.y = uievt.pageY;
        }

        final Offset ofs = new DOMQuery(target).documentOffset;
        _offset.left -= ofs.left;
        _offset.top -= ofs.top;
      } catch (final e) {
        print("Faile to get offset for $this, $e");
      }
    }
    return _offset;
  }

  /** Returns the view that this event is targeting  to.
   */
  View target;
  /** The view that is handling this event currently.
   */
  View currentTarget;

  /** The DOM event that causes this view event, or null if not available.
   */
  Event get domEvent() => _domEvt;

  /** Returns the time stamp. */
  int get timeStamp() => _stamp;
  /** Returns the event's type. */
  String get type() => _type;

  /** Returns whether this event's propagation is stopped.
   *
   * Default: false.
   *
   * It becomes true if [stopPropagation] is called,
   * and then all remaining event listeners are ignored.
   */
  bool isPropagationStopped() => _propStop;
  /** Stops the propagation.
   *Once called, all remaining event listeners, if any, are ignored.
   */
  void stopPropagation() {
    _propStop = true;
  }

  String toString() => "ViewEvent($target,$type)";
}
