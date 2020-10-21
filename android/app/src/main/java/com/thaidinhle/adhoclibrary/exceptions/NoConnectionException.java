package com.thaidinhle.adhoclibrary;

/**
 * <p>This class signals that a No Connection Exception exception has occurred.</p>
 *
 * @author Gaulthier Gain
 * @version 1.0
 */
public class NoConnectionException extends Exception {
    /**
     * Constructor
     *
     * @param message a String values which represents the cause of the exception
     */
    public NoConnectionException(String message) {
        super(message);
    }
}
