package com.google_mlkit_text_recognition;

import android.content.Context;
import android.graphics.Point;
import android.graphics.Rect;

import androidx.annotation.NonNull;

import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.Text;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions;
import com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions;
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions;
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;
import com.google_mlkit_commons.InputImageConverter;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class TextRecognizer implements MethodChannel.MethodCallHandler {
    private static final String START = "vision#startTextRecognizer";
    private static final String CLOSE = "vision#closeTextRecognizer";

    private final Context context;
    private com.google.mlkit.vision.text.TextRecognizer textRecognizer;
    private int script = -1;

    public TextRecognizer(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String method = call.method;
        switch (method) {
            case START:
                handleDetection(call, result);
                break;
            case CLOSE:
                closeDetector();
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void handleDetection(MethodCall call, final MethodChannel.Result result) {
        Map<String, Object> imageData = (Map<String, Object>) call.argument("imageData");
        InputImage inputImage = InputImageConverter.getInputImageFromData(imageData, context, result);
        if (inputImage == null) return;

        int script = (int) call.argument("script");
        if (this.script != script || textRecognizer == null) initializeDetector(script);

        textRecognizer.process(inputImage)
                .addOnSuccessListener(text -> {
                    Map<String, Object> textResult = new HashMap<>();

                    textResult.put("text", text.getText());

                    List<Map<String, Object>> textBlocks = new ArrayList<>();
                    for (Text.TextBlock block : text.getTextBlocks()) {
                        Map<String, Object> blockData = new HashMap<>();

                        addData(blockData,
                                block.getText(),
                                block.getBoundingBox(),
                                block.getCornerPoints(),
                                block.getRecognizedLanguage());

                        List<Map<String, Object>> textLines = new ArrayList<>();
                        for (Text.Line line : block.getLines()) {
                            Map<String, Object> lineData = new HashMap<>();

                            addData(lineData,
                                    line.getText(),
                                    line.getBoundingBox(),
                                    line.getCornerPoints(),
                                    line.getRecognizedLanguage());

                            List<Map<String, Object>> elementsData = new ArrayList<>();
                            for (Text.Element element : line.getElements()) {
                                Map<String, Object> elementData = new HashMap<>();

                                addData(elementData,
                                        element.getText(),
                                        element.getBoundingBox(),
                                        element.getCornerPoints(),
                                        element.getRecognizedLanguage());

                                elementsData.add(elementData);
                            }
                            lineData.put("elements", elementsData);
                            textLines.add(lineData);
                        }
                        blockData.put("lines", textLines);
                        textBlocks.add(blockData);
                    }
                    textResult.put("blocks", textBlocks);
                    result.success(textResult);
                })
                .addOnFailureListener(e -> result.error("TextRecognizerError", e.toString(), null));
    }

    private void addData(Map<String, Object> addTo,
                         String text,
                         Rect rect,
                         Point[] cornerPoints,
                         String recognizedLanguage) {
        List<String> recognizedLanguages = new ArrayList<>();
        recognizedLanguages.add(recognizedLanguage);
        List<Map<String, Integer>> points = new ArrayList<>();
        addPoints(cornerPoints, points);
        addTo.put("points", points);
        addTo.put("rect", getBoundingPoints(rect));
        addTo.put("recognizedLanguages", recognizedLanguages);
        addTo.put("text", text);
    }

    private void addPoints(Point[] cornerPoints, List<Map<String, Integer>> points) {
        for (Point point : cornerPoints) {
            Map<String, Integer> p = new HashMap<>();
            p.put("x", point.x);
            p.put("y", point.y);
            points.add(p);
        }
    }

    private Map<String, Integer> getBoundingPoints(Rect rect) {
        Map<String, Integer> frame = new HashMap<>();
        frame.put("left", rect.left);
        frame.put("right", rect.right);
        frame.put("top", rect.top);
        frame.put("bottom", rect.bottom);
        return frame;
    }

    private void closeDetector() {
        if (textRecognizer == null) return;
        textRecognizer.close();
    }

    private void initializeDetector(int script) {
        closeDetector();
        this.script = script;
        switch (script) {
            case 0:
                textRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
                break;
            case 1:
                textRecognizer = TextRecognition.getClient(new ChineseTextRecognizerOptions.Builder().build());
                break;
            case 2:
                textRecognizer = TextRecognition.getClient(new DevanagariTextRecognizerOptions.Builder().build());
                break;
            case 3:
                textRecognizer = TextRecognition.getClient(new JapaneseTextRecognizerOptions.Builder().build());
                break;
            case 4:
                textRecognizer = TextRecognition.getClient(new KoreanTextRecognizerOptions.Builder().build());
        }
    }
}
