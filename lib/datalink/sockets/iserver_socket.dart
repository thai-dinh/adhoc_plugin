abstract class IServerSocket {
  void close();

  void accept(Function onEvent);
}