abstract class ISocket {
  Object get socket;

  void close();

  String remoteAddress();

  Object inputStream();

  Object outputStream();
}