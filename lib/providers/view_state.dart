/// The explicit UI states every data-loading provider exposes. Screens switch
/// on this to render loading / error / empty / content — required everywhere.
enum ViewState { idle, loading, success, empty, error }
