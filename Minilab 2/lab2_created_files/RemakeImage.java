import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.util.HexFormat;

public class RemakeImage {
    public static void main(String[] args) {
        try (OutputStream out = new BufferedOutputStream(new FileOutputStream(path))) {
    out.write(bytes);
}
    }
}
