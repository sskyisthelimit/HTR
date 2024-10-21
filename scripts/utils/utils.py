def sort_lines_by_top(boxes):
    return sorted(boxes, key=lambda box: box.xyxy[0][1].item())


def sort_words_by_left(boxes):
    return sorted(boxes, key=lambda box: box.xyxy[0][0].item())


def intersection_area(box1, box2):

    """Calculates the area of intersection between two boxes."""
    x1 = max(box1[0], box2[0])
    y1 = max(box1[1], box2[1])
    x2 = min(box1[2], box2[2])
    y2 = min(box1[3], box2[3])

    inter_width = max(0, x2 - x1)
    inter_height = max(0, y2 - y1)

    return inter_width * inter_height
