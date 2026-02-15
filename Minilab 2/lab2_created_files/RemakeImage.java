import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.awt.image.DataBufferByte;

import javax.imageio.ImageIO;
import java.io.File;
import java.awt.image.BufferedImage;
import java.util.HexFormat;

public class RemakeImage {

    public static void main(String[] args) {

        final String INPUT_FILE = "C:\\Users\\tando\\Desktop\\UWCoding\\ECE554\\ECE554_Tandon\\Minilab 2\\lab2_created_files\\written_data.hex";
        final String OUTPUT_FILE = "C:\\Users\\tando\\Desktop\\UWCoding\\ECE554\\ECE554_Tandon\\Minilab 2\\lab2_created_files\\created_image.png";
        final int OUTPUT_WIDTH = 640;
        final int OUTPUT_HEIGHT = 480;
        

        try {

            Path path = Path.of(INPUT_FILE);
            String s = Files.readString(path).replaceAll("\\s+", "");

            byte[] toWrite = HexFormat.of().parseHex(s);

            BufferedImage newImage = new BufferedImage(OUTPUT_WIDTH, OUTPUT_HEIGHT, BufferedImage.TYPE_BYTE_GRAY);
            byte[] newData = ((DataBufferByte) newImage.getRaster().getDataBuffer()).getData();

            for (int i = 0; i < Math.min(toWrite.length, newData.length); i++) {
                newData[i] = toWrite[i];
            }
    
            ImageIO.write(newImage, "png", new File(OUTPUT_FILE));
            
        }

        catch (IOException e) {
            System.out.println("Unexpected error");
        }

    }
}
